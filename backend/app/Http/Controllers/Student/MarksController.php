<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\Enrollment;
use Illuminate\Http\Request;

class MarksController extends Controller
{
    /**
     * GET /student/{studentId}/marks
     *
     * List all published marks for the student.
     * Filters: subject_id, section_id, assessment_type
     */
    public function index(int $studentId, Request $request)
    {
        $query = AssessmentResult::where('student_id', $studentId)
            ->whereNotNull('publishedat')
            ->with(['assessment.subject', 'assessment.section.schoolClass']);

        if ($request->filled('subject_id')) {
            $query->whereHas('assessment', fn ($q) => $q->where('subject_id', $request->subject_id));
        }

        if ($request->filled('section_id')) {
            $query->whereHas('assessment', fn ($q) => $q->where('section_id', $request->section_id));
        }

        if ($request->filled('assessment_type')) {
            $query->whereHas('assessment', fn ($q) => $q->where('assessmenttype', $request->assessment_type));
        }

        $results = $query->orderByDesc('publishedat')
            ->paginate($request->input('per_page', 20));

        return response()->json($results);
    }

    /**
     * GET /student/{studentId}/marks/summary
     *
     * Per-subject average, total assessments, and overall average.
     */
    public function summary(int $studentId)
    {
        $results = AssessmentResult::where('student_id', $studentId)
            ->whereNotNull('publishedat')
            ->with('assessment.subject')
            ->get();

        $bySubject = $results->groupBy(fn ($r) => $r->assessment->subject_id)->map(function ($group) {
            $subject = $group->first()->assessment->subject;
            $percentages = $group->map(fn ($r) => ($r->score / $r->assessment->maxscore) * 100);

            return [
                'subject_id'        => $subject->id,
                'subject_name'      => $subject->name,
                'total_assessments' => $group->count(),
                'average_percentage' => round($percentages->avg(), 2),
                'highest'           => round($percentages->max(), 2),
                'lowest'            => round($percentages->min(), 2),
            ];
        })->values();

        $overallAvg = $bySubject->isNotEmpty()
            ? round($bySubject->avg('average_percentage'), 2)
            : 0;

        return response()->json([
            'subjects'         => $bySubject,
            'overall_average'  => $overallAvg,
            'total_assessments' => $results->count(),
        ]);
    }
}
