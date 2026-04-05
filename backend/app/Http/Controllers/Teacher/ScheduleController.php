<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\ScheduleSlot;
use App\Models\Teacher;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    /**
     * Get a teacher's weekly schedule, grouped by day.
     *
     * Route: GET /api/teacher/{teacherId}/schedule
     *
     * Query params:
     *   termname - filter by term (optional)
     */
    public function index(int $teacherId, Request $request)
    {
        $teacher = Teacher::with('user')->findOrFail($teacherId);

        $query = ScheduleSlot::with([
            'schedule.section.schoolClass.schoolYear',
            'subject',
        ])->where('teacher_id', $teacherId);

        if ($request->filled('termname')) {
            $query->whereHas('schedule', function ($q) use ($request) {
                $q->where('termname', $request->termname);
            });
        }

        $slots = $query->get();

        $dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

        $grouped = $slots
            ->sortBy('starttime')
            ->groupBy('dayofweek')
            ->sortBy(fn ($_, $day) => array_search($day, $dayOrder));

        $schedule = $grouped->map(function ($daySlots, $day) {
            return [
                'day'   => $day,
                'slots' => $daySlots->values()->map(function ($slot) {
                    return [
                        'slot_id'     => $slot->slot_id,
                        'start_time'  => $slot->starttime,
                        'subject'     => $slot->subject->name,
                        'section'     => $slot->schedule->section->name,
                        'grade'       => $slot->schedule->section->schoolClass->name,
                        'school_year' => $slot->schedule->section->schoolClass->schoolYear->name,
                        'term'        => $slot->schedule->termname,
                    ];
                }),
            ];
        })->values();

        return response()->json([
            'teacher'  => [
                'id'   => $teacher->teacher_id,
                'name' => $teacher->user->name,
            ],
            'schedule' => $schedule,
        ]);
    }
}
