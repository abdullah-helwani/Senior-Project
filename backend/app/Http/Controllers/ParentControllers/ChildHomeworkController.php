<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use App\Models\Guardian;
use App\Models\Homework;
use Illuminate\Http\Request;

class ChildHomeworkController extends Controller
{
    /**
     * GET /parent/{parentId}/children/{studentId}/homework
     *
     * View homework assigned to a child's section.
     * Filters: subject_id, status (upcoming|overdue)
     */
    public function index(int $parentId, int $studentId, Request $request)
    {
        $this->authorizeChild($parentId, $studentId);

        $sectionIds = Enrollment::where('student_id', $studentId)
            ->where('status', 'active')
            ->pluck('section_id');

        $query = Homework::whereIn('section_id', $sectionIds)
            ->with(['subject', 'teacher.user', 'section.schoolClass']);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->input('status') === 'upcoming') {
            $query->where('due_date', '>=', now()->toDateString());
        } elseif ($request->input('status') === 'overdue') {
            $query->where('due_date', '<', now()->toDateString());
        }

        $homework = $query->orderByDesc('due_date')
            ->paginate($request->input('per_page', 20));

        return response()->json($homework);
    }

    private function authorizeChild(int $parentId, int $studentId): void
    {
        Guardian::where('parent_id', $parentId)
            ->whereHas('studentLinks', fn ($q) => $q->where('student_id', $studentId))
            ->firstOrFail();
    }
}
