<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use App\Models\Student;

class ScheduleController extends Controller
{
    /**
     * GET /student/{studentId}/schedule
     *
     * Returns the weekly timetable for the student's active enrollment section.
     */
    public function index(int $studentId)
    {
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

        // Group slots by day of week
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
}
