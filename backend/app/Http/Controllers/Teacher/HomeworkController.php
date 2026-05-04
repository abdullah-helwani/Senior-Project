<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use App\Models\Homework;
use App\Models\HomeworkSubmission;
use App\Models\Teacher;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class HomeworkController extends Controller
{
    /**
     * List all homework assigned by this teacher.
     *
     * Query params:
     *   subject_id - filter by subject
     *   section_id - filter by section
     */
    public function index(int $teacherId, Request $request)
    {
        Teacher::findOrFail($teacherId);

        $query = Homework::with(['subject', 'section.schoolClass'])
            ->withCount('submissions as submission_count')
            ->where('teacher_id', $teacherId);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        $page = $query->latest('due_date')
            ->paginate($request->input('per_page', 15));

        // Flatten each Homework row into the shape the Flutter client expects.
        // Frontend `TeacherHomeworkModel.fromJson` reads strings for subject /
        // class_name, so we resolve the eager-loaded relations to scalars.
        $page->getCollection()->transform(fn ($h) => [
            'id'                => $h->id,
            'title'             => (string) ($h->title ?? ''),
            'description'       => (string) ($h->description ?? ''),
            'due_date'          => optional($h->due_date)->toDateString() ?? '',
            'status'            => 'published',
            'subject'           => optional($h->subject)->name ?? '',
            'class_name'        => optional(optional($h->section)->schoolClass)->name
                                    ?? optional($h->section)->name
                                    ?? '',
            'submission_count'  => (int) ($h->submission_count ?? 0),
            'total_students'    => $h->section
                ? \App\Models\Enrollment::where('section_id', $h->section_id)
                    ->where('status', 'active')->count()
                : 0,
        ]);

        return response()->json($page);
    }

    /**
     * Show a single homework with section/subject details.
     */
    public function show(int $teacherId, int $homeworkId)
    {
        $homework = Homework::with(['subject', 'section.schoolClass.schoolYear', 'teacher.user'])
            ->where('teacher_id', $teacherId)
            ->findOrFail($homeworkId);

        return response()->json($homework);
    }

    /**
     * Create (assign) new homework to a section.
     */
    public function store(int $teacherId, Request $request)
    {
        Teacher::findOrFail($teacherId);

        $request->validate([
            'subject_id'  => 'required|exists:subjects,id',
            'section_id'  => 'required|exists:sections,id',
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'due_date'    => 'required|date|after:today',
        ]);

        $teacher = Teacher::with('user')->find($teacherId);

        $homework = Homework::create([
            'teacher_id'  => $teacherId,
            'subject_id'  => $request->subject_id,
            'section_id'  => $request->section_id,
            'title'       => $request->title,
            'description' => $request->description,
            'due_date'    => $request->due_date,
        ]);

        $homework->load(['subject', 'section.schoolClass']);

        // Notify all students enrolled in this section
        app(NotificationService::class)->notifySection($request->section_id, [
            'title'           => "New Homework: {$homework->title} ({$homework->subject->name}) — due {$homework->due_date->format('M d, Y')}",
            'createdbyuserid' => $teacher->user_id,
            'channel'         => 'app',
        ]);

        return response()->json($homework, 201);
    }

    /**
     * Update a homework assignment.
     */
    public function update(int $teacherId, int $homeworkId, Request $request)
    {
        $homework = Homework::where('teacher_id', $teacherId)->findOrFail($homeworkId);

        $request->validate([
            'title'       => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'due_date'    => 'sometimes|date',
        ]);

        $homework->update($request->only(['title', 'description', 'due_date']));

        return response()->json($homework->load(['subject', 'section.schoolClass']));
    }

    /**
     * Delete a homework assignment.
     */
    public function destroy(int $teacherId, int $homeworkId)
    {
        Homework::where('teacher_id', $teacherId)->findOrFail($homeworkId)->delete();

        return response()->json(['message' => 'Homework deleted successfully.']);
    }

    /**
     * GET /teacher/{teacherId}/homework/{homeworkId}/submissions
     *
     * View all submissions for a homework assignment with summary stats.
     * Filters: status (submitted|graded)
     */
    public function submissions(int $teacherId, int $homeworkId, Request $request)
    {
        $homework = Homework::where('teacher_id', $teacherId)->findOrFail($homeworkId);

        $query = HomeworkSubmission::where('homework_id', $homeworkId)
            ->with('student');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $submissions = $query->orderByDesc('submittedat')->get();

        // Count enrolled students to calculate submission rate
        $enrolledCount = Enrollment::where('section_id', $homework->section_id)
            ->where('status', 'active')
            ->count();

        $gradedSubmissions = $submissions->where('status', 'graded');

        $summary = [
            'total_enrolled'  => $enrolledCount,
            'total_submitted' => $submissions->count(),
            'total_graded'    => $gradedSubmissions->count(),
            'not_submitted'   => $enrolledCount - $submissions->count(),
            'average_score'   => $gradedSubmissions->isNotEmpty()
                ? round($gradedSubmissions->avg('score'), 2)
                : null,
        ];

        return response()->json([
            'homework'    => $homework->load('subject'),
            'summary'     => $summary,
            'submissions' => $submissions,
        ]);
    }

    /**
     * PUT /teacher/{teacherId}/homework/{homeworkId}/submissions/{submissionId}/grade
     *
     * Grade a student's submission.
     */
    public function grade(int $teacherId, int $homeworkId, int $submissionId, Request $request)
    {
        Homework::where('teacher_id', $teacherId)->findOrFail($homeworkId);

        $submission = HomeworkSubmission::where('submission_id', $submissionId)
            ->where('homework_id', $homeworkId)
            ->firstOrFail();

        $request->validate([
            'score' => 'required|numeric|min:0',
        ]);

        $submission->update([
            'score'  => $request->score,
            'status' => 'graded',
        ]);

        return response()->json($submission->load('student'));
    }
}
