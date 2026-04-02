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
     *   term_name - filter by term (optional, returns all terms if omitted)
     */
    public function index(int $teacherId, Request $request)
    {
        $teacher = Teacher::with('user')->findOrFail($teacherId);

        $query = ScheduleSlot::with([
            'schedule.section.schoolClass.schoolYear',
            'subject',
        ])
        ->where('teacher_id', $teacherId);

        if ($request->filled('term_name')) {
            $query->whereHas('schedule', function ($q) use ($request) {
                $q->where('term_name', $request->term_name);
            });
        }

        $slots = $query->get();

        // Group by day in correct weekday order
        $dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

        $grouped = $slots
            ->sortBy(fn ($s) => [$s->start_time])
            ->groupBy('day_of_week')
            ->sortBy(fn ($_, $day) => array_search($day, $dayOrder));

        $schedule = $grouped->map(function ($daySlots, $day) {
            return [
                'day'   => $day,
                'slots' => $daySlots->values()->map(function ($slot) {
                    return [
                        'slot_id'    => $slot->id,
                        'start_time' => $slot->start_time,
                        'end_time'   => $slot->end_time,
                        'subject'    => $slot->subject->name,
                        'section'    => $slot->schedule->section->name,
                        'grade'      => $slot->schedule->section->schoolClass->name,
                        'school_year'=> $slot->schedule->section->schoolClass->schoolYear->name,
                        'term'       => $slot->schedule->term_name,
                    ];
                }),
            ];
        })->values();

        return response()->json([
            'teacher'  => [
                'id'   => $teacher->id,
                'name' => $teacher->user->name,
            ],
            'schedule' => $schedule,
        ]);
    }
}
