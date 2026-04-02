<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Assessment;
use App\Models\AssessmentResult;
use App\Models\Enrollment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AssessmentController extends Controller
{
    /**
     * List all assessments.
     *
     * Query params:
     *   subject_id      - filter by subject
     *   section_id      - filter by section
     *   assessment_type - exam | quiz | assignment | project | other
     */
    public function index(Request $request)
    {
        $query = Assessment::with(['subject', 'section.schoolClass', 'createdBy']);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('assessment_type')) {
            $query->where('assessment_type', $request->assessment_type);
        }

        return response()->json($query->latest('date')->paginate($request->input('per_page', 15)));
    }

    /**
     * Create a new assessment.
     */
    public function store(Request $request)
    {
        $request->validate([
            'subject_id'      => 'required|exists:subjects,id',
            'section_id'      => 'required|exists:sections,id',
            'title'           => 'required|string|max:255',
            'created_by_user_id' => 'required|exists:users,id',
            'assessment_type' => 'required|in:exam,quiz,assignment,project,other',
            'date'            => 'required|date',
            'max_score'       => 'required|numeric|min:1',
        ]);

        $assessment = Assessment::create($request->only([
            'subject_id', 'section_id', 'title',
            'created_by_user_id', 'assessment_type', 'date', 'max_score',
        ]));

        return response()->json($assessment->load(['subject', 'section.schoolClass']), 201);
    }

    /**
     * Show one assessment with all student results.
     */
    public function show(int $id)
    {
        $assessment = Assessment::with([
            'subject',
            'section.schoolClass.schoolYear',
            'createdBy',
            'results.student.user',
        ])->findOrFail($id);

        return response()->json($assessment);
    }

    /**
     * Bulk add or update marks for students in an assessment.
     *
     * Body: { "results": [ { "student_id": 1, "score": 87 }, ... ] }
     *
     * - Auto-calculates letter grade.
     * - Uses upsert so re-submitting the same student just updates their score.
     */
    public function storeResults(Request $request, int $id)
    {
        $assessment = Assessment::findOrFail($id);

        $request->validate([
            'results'             => 'required|array|min:1',
            'results.*.student_id' => 'required|exists:students,id',
            'results.*.score'     => "required|numeric|min:0|max:{$assessment->max_score}",
        ]);

        // Verify all students are actually enrolled in this section
        $enrolledIds = Enrollment::where('section_id', $assessment->section_id)
            ->where('status', 'active')
            ->pluck('student_id')
            ->toArray();

        $invalidStudents = collect($request->results)
            ->pluck('student_id')
            ->diff($enrolledIds);

        if ($invalidStudents->isNotEmpty()) {
            return response()->json([
                'message'          => 'Some students are not enrolled in this section.',
                'invalid_students' => $invalidStudents->values(),
            ], 422);
        }

        $now = now();

        $rows = collect($request->results)->map(function ($item) use ($assessment, $now) {
            return [
                'assessment_id' => $assessment->id,
                'student_id'    => $item['student_id'],
                'score'         => $item['score'],
                'grade'         => AssessmentResult::calculateGrade($item['score'], $assessment->max_score),
                'published_at'  => $now,
                'created_at'    => $now,
                'updated_at'    => $now,
            ];
        })->toArray();

        DB::transaction(function () use ($rows) {
            AssessmentResult::upsert(
                $rows,
                ['assessment_id', 'student_id'],   // unique keys
                ['score', 'grade', 'published_at', 'updated_at'] // columns to update on conflict
            );
        });

        return response()->json([
            'message' => 'Marks saved successfully.',
            'count'   => count($rows),
        ]);
    }

    /**
     * Get all results for an assessment (for review).
     */
    public function results(int $id)
    {
        $assessment = Assessment::with(['subject', 'section.schoolClass'])->findOrFail($id);

        $results = AssessmentResult::with('student.user')
            ->where('assessment_id', $id)
            ->get()
            ->map(function ($r) use ($assessment) {
                return [
                    'result_id'    => $r->id,
                    'student_id'   => $r->student_id,
                    'student_name' => $r->student->user->name,
                    'score'        => $r->score,
                    'max_score'    => $assessment->max_score,
                    'percentage'   => round(($r->score / $assessment->max_score) * 100, 1),
                    'grade'        => $r->grade,
                    'published_at' => $r->published_at,
                ];
            });

        return response()->json([
            'assessment' => [
                'id'              => $assessment->id,
                'title'           => $assessment->title,
                'subject'         => $assessment->subject->name,
                'section'         => $assessment->section->name,
                'class'           => $assessment->section->schoolClass->name,
                'assessment_type' => $assessment->assessment_type,
                'date'            => $assessment->date,
                'max_score'       => $assessment->max_score,
            ],
            'results'    => $results,
            'summary'    => [
                'total_students' => $results->count(),
                'average_score'  => round($results->avg('score'), 2),
                'highest_score'  => $results->max('score'),
                'lowest_score'   => $results->min('score'),
                'pass_rate'      => $results->count()
                    ? round(($results->where('grade', '!=', 'F')->count() / $results->count()) * 100, 1)
                    : 0,
            ],
        ]);
    }

    /**
     * Update an assessment's details (not results — use storeResults for that).
     */
    public function update(Request $request, int $id)
    {
        $assessment = Assessment::findOrFail($id);

        $request->validate([
            'title'           => 'sometimes|string|max:255',
            'assessment_type' => 'sometimes|in:exam,quiz,assignment,project,other',
            'date'            => 'sometimes|date',
            'max_score'       => 'sometimes|numeric|min:1',
        ]);

        $assessment->update($request->only(['title', 'assessment_type', 'date', 'max_score']));

        return response()->json($assessment->load(['subject', 'section.schoolClass']));
    }

    /**
     * Delete an assessment and all its results.
     */
    public function destroy(int $id)
    {
        Assessment::findOrFail($id)->delete();

        return response()->json(['message' => 'Assessment deleted successfully.']);
    }
}
