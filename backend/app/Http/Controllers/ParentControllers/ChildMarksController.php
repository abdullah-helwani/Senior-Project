<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\Guardian;
use Illuminate\Http\Request;

class ChildMarksController extends Controller
{
    /**
     * GET /parent/{parentId}/children/{studentId}/marks
     */
    public function index(int $parentId, int $studentId, Request $request)
    {
        $this->authorizeChild($parentId, $studentId);

        $query = AssessmentResult::where('student_id', $studentId)
            ->whereNotNull('publishedat')
            ->with(['assessment.subject', 'assessment.section.schoolClass']);

        if ($request->filled('subject_id')) {
            $query->whereHas('assessment', fn ($q) => $q->where('subject_id', $request->subject_id));
        }

        if ($request->filled('assessment_type')) {
            $query->whereHas('assessment', fn ($q) => $q->where('assessmenttype', $request->assessment_type));
        }

        $results = $query->orderByDesc('publishedat')
            ->paginate($request->input('per_page', 20));

        return response()->json($results);
    }

    /**
     * GET /parent/{parentId}/children/{studentId}/marks/summary
     */
    public function summary(int $parentId, int $studentId)
    {
        $this->authorizeChild($parentId, $studentId);

        $results = AssessmentResult::where('student_id', $studentId)
            ->whereNotNull('publishedat')
            ->with('assessment.subject')
            ->get();

        $bySubject = $results->groupBy(fn ($r) => $r->assessment->subject_id)->map(function ($group) {
            $subject = $group->first()->assessment->subject;
            $percentages = $group->map(fn ($r) => ($r->score / $r->assessment->maxscore) * 100);

            return [
                'subject_id'         => $subject->id,
                'subject_name'       => $subject->name,
                'total_assessments'  => $group->count(),
                'average_percentage' => round($percentages->avg(), 2),
                'highest'            => round($percentages->max(), 2),
                'lowest'             => round($percentages->min(), 2),
            ];
        })->values();

        $overallAvg = $bySubject->isNotEmpty()
            ? round($bySubject->avg('average_percentage'), 2)
            : 0;

        return response()->json([
            'subjects'          => $bySubject,
            'overall_average'   => $overallAvg,
            'total_assessments' => $results->count(),
        ]);
    }

    private function authorizeChild(int $parentId, int $studentId): void
    {
        $guardian = Guardian::where('parent_id', $parentId)
            ->whereHas('studentLinks', fn ($q) => $q->where('student_id', $studentId))
            ->firstOrFail();
    }
}
