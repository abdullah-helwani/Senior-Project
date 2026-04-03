<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Guardian;
use App\Models\Schedule;
use App\Models\Student;

class ChildScheduleController extends Controller
{
    /**
     * GET /parent/{parentId}/children/{studentId}/schedule
     *
     * View the child's weekly timetable based on active enrollment.
     */
    public function index(int $parentId, int $studentId)
    {
        $this->authorizeChild($parentId, $studentId);

        $student = Student::with('activeEnrollment')->findOrFail($studentId);

        if (! $student->activeEnrollment) {
            return response()->json(['message' => 'No active enrollment found.'], 404);
        }

        $sectionId = $student->activeEnrollment->section_id;

        $schedule = Schedule::where('section_id', $sectionId)
            ->with(['section.schoolClass', 'slots.subject', 'slots.teacher.user'])
            ->first();

        if (! $schedule) {
            return response()->json(['message' => 'No schedule found for this section.'], 404);
        }

        $timetable = $schedule->slots
            ->sortBy('starttime')
            ->groupBy('dayofweek')
            ->map(fn ($slots) => $slots->values());

        return response()->json([
            'section'   => $schedule->section->name,
            'class'     => $schedule->section->schoolClass->name,
            'term'      => $schedule->termname,
            'timetable' => $timetable,
        ]);
    }

    private function authorizeChild(int $parentId, int $studentId): void
    {
        Guardian::where('parent_id', $parentId)
            ->whereHas('studentLinks', fn ($q) => $q->where('student_id', $studentId))
            ->firstOrFail();
    }
}
