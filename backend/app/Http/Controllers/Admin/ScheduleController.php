<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use App\Models\ScheduleSlot;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ScheduleController extends Controller
{
    /**
     * GET /admin/schedules
     *
     * List all schedules. Filters: section_id
     */
    public function index(Request $request)
    {
        $query = Schedule::with(['section.schoolClass', 'slots.subject', 'slots.teacher.user']);

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        $schedules = $query->paginate($request->input('per_page', 20));

        return response()->json($schedules);
    }

    /**
     * POST /admin/schedules
     *
     * Create a schedule for a section, optionally with slots.
     */
    public function store(Request $request)
    {
        $request->validate([
            'section_id'             => 'required|integer',
            'termname'               => 'required|string|max:255',
            'slots'                  => 'sometimes|array',
            'slots.*.subject_id'     => 'required_with:slots|exists:subjects,id',
            'slots.*.teacher_id'     => 'required_with:slots|exists:teachers,id',
            'slots.*.dayofweek'      => 'required_with:slots|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'slots.*.starttime'      => 'required_with:slots|date_format:H:i',
        ]);

        $schedule = DB::transaction(function () use ($request) {
            $schedule = Schedule::create([
                'section_id' => $request->section_id,
                'termname'   => $request->termname,
            ]);

            if ($request->filled('slots')) {
                foreach ($request->slots as $slot) {
                    ScheduleSlot::create([
                        'schedule_id' => $schedule->schedule_id,
                        'subject_id'  => $slot['subject_id'],
                        'teacher_id'  => $slot['teacher_id'],
                        'dayofweek'   => $slot['dayofweek'],
                        'starttime'   => $slot['starttime'],
                    ]);
                }
            }

            return $schedule;
        });

        return response()->json(
            $schedule->load(['section.schoolClass', 'slots.subject', 'slots.teacher.user']),
            201
        );
    }

    /**
     * GET /admin/schedules/{id}
     */
    public function show(int $id)
    {
        $schedule = Schedule::where('schedule_id', $id)
            ->with(['section.schoolClass', 'slots.subject', 'slots.teacher.user'])
            ->firstOrFail();

        return response()->json($schedule);
    }

    /**
     * PUT /admin/schedules/{id}
     *
     * Update schedule info (termname, section_id).
     */
    public function update(int $id, Request $request)
    {
        $schedule = Schedule::where('schedule_id', $id)->firstOrFail();

        $request->validate([
            'section_id' => 'sometimes|integer',
            'termname'   => 'sometimes|string|max:255',
        ]);

        $schedule->update($request->only(['section_id', 'termname']));

        return response()->json(
            $schedule->load(['section.schoolClass', 'slots.subject', 'slots.teacher.user'])
        );
    }

    /**
     * DELETE /admin/schedules/{id}
     *
     * Delete a schedule and all its slots.
     */
    public function destroy(int $id)
    {
        $schedule = Schedule::where('schedule_id', $id)->firstOrFail();

        // Delete slots first, then the schedule
        ScheduleSlot::where('schedule_id', $id)->delete();
        $schedule->delete();

        return response()->json(['message' => 'Schedule deleted successfully.']);
    }

    // ─────────────────────────────────────────────
    // SLOT MANAGEMENT
    // ─────────────────────────────────────────────

    /**
     * POST /admin/schedules/{id}/slots
     *
     * Add a slot to an existing schedule.
     */
    public function addSlot(int $id, Request $request)
    {
        Schedule::where('schedule_id', $id)->firstOrFail();

        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'teacher_id' => 'required|exists:teachers,id',
            'dayofweek'  => 'required|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'starttime'  => 'required|date_format:H:i',
        ]);

        $slot = ScheduleSlot::create([
            'schedule_id' => $id,
            'subject_id'  => $request->subject_id,
            'teacher_id'  => $request->teacher_id,
            'dayofweek'   => $request->dayofweek,
            'starttime'   => $request->starttime,
        ]);

        return response()->json(
            $slot->load(['subject', 'teacher.user']),
            201
        );
    }

    /**
     * PUT /admin/schedules/{id}/slots/{slotId}
     *
     * Update a specific slot.
     */
    public function updateSlot(int $id, int $slotId, Request $request)
    {
        $slot = ScheduleSlot::where('schedule_id', $id)
            ->where('slot_id', $slotId)
            ->firstOrFail();

        $request->validate([
            'subject_id' => 'sometimes|exists:subjects,id',
            'teacher_id' => 'sometimes|exists:teachers,id',
            'dayofweek'  => 'sometimes|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'starttime'  => 'sometimes|date_format:H:i',
        ]);

        $slot->update($request->only(['subject_id', 'teacher_id', 'dayofweek', 'starttime']));

        return response()->json($slot->load(['subject', 'teacher.user']));
    }

    /**
     * DELETE /admin/schedules/{id}/slots/{slotId}
     *
     * Remove a specific slot.
     */
    public function removeSlot(int $id, int $slotId)
    {
        ScheduleSlot::where('schedule_id', $id)
            ->where('slot_id', $slotId)
            ->firstOrFail()
            ->delete();

        return response()->json(['message' => 'Slot removed successfully.']);
    }
}
