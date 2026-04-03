<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\HomeworkSubmission;
use Illuminate\Http\Request;

class SubmissionController extends Controller
{
    /**
     * GET /student/{studentId}/submissions
     *
     * List all submissions by this student.
     * Filters: homework_id, status
     */
    public function index(int $studentId, Request $request)
    {
        $query = HomeworkSubmission::where('student_id', $studentId)
            ->with(['homework.subject', 'homework.section.schoolClass']);

        if ($request->filled('homework_id')) {
            $query->where('homework_id', $request->homework_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $submissions = $query->orderByDesc('submittedat')
            ->paginate($request->input('per_page', 20));

        return response()->json($submissions);
    }

    /**
     * POST /student/{studentId}/submissions
     *
     * Submit homework.
     */
    public function store(int $studentId, Request $request)
    {
        $request->validate([
            'homework_id' => 'required|integer',
        ]);

        // Check if already submitted
        $exists = HomeworkSubmission::where('homework_id', $request->homework_id)
            ->where('student_id', $studentId)
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'You have already submitted this homework.'], 422);
        }

        $submission = HomeworkSubmission::create([
            'homework_id' => $request->homework_id,
            'student_id'  => $studentId,
            'submittedat' => now(),
            'status'      => 'submitted',
        ]);

        return response()->json(
            $submission->load(['homework.subject']),
            201
        );
    }

    /**
     * GET /student/{studentId}/submissions/{id}
     */
    public function show(int $studentId, int $id)
    {
        $submission = HomeworkSubmission::where('submission_id', $id)
            ->where('student_id', $studentId)
            ->with(['homework.subject', 'homework.teacher.user'])
            ->firstOrFail();

        return response()->json($submission);
    }
}
