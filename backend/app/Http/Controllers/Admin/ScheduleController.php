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

        // Check for conflicts in the batch before creating anything
        if ($request->filled('slots')) {
            foreach ($request->slots as $i => $slot) {
                $conflicts = $this->detectConflicts(
                    $slot['teacher_id'],
                    $request->section_id,
                    $slot['dayofweek'],
                    $slot['starttime']
                );
                if ($conflicts) {
                    return response()->json([
                        'message' => "Conflict in slot #" . ($i + 1) . ": {$conflicts}",
                    ], 422);
                }
            }

            // Also check for conflicts within the batch itself
            $seen = [];
            foreach ($request->slots as $i => $slot) {
                $teacherKey = "teacher:{$slot['teacher_id']}|{$slot['dayofweek']}|{$slot['starttime']}";
                $sectionKey = "section:{$request->section_id}|{$slot['dayofweek']}|{$slot['starttime']}";

                if (isset($seen[$teacherKey])) {
                    return response()->json([
                        'message' => "Conflict in slot #" . ($i + 1) . ": Teacher is already assigned at {$slot['dayofweek']} {$slot['starttime']} in another slot in this batch.",
                    ], 422);
                }
                if (isset($seen[$sectionKey])) {
                    return response()->json([
                        'message' => "Conflict in slot #" . ($i + 1) . ": Section already has a slot at {$slot['dayofweek']} {$slot['starttime']} in this batch.",
                    ], 422);
                }
                $seen[$teacherKey] = true;
                $seen[$sectionKey] = true;
            }
        }

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
        $schedule = Schedule::where('schedule_id', $id)->firstOrFail();

        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'teacher_id' => 'required|exists:teachers,id',
            'dayofweek'  => 'required|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'starttime'  => 'required|date_format:H:i',
        ]);

        $conflicts = $this->detectConflicts(
            $request->teacher_id,
            $schedule->section_id,
            $request->dayofweek,
            $request->starttime
        );
        if ($conflicts) {
            return response()->json(['message' => $conflicts], 422);
        }

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
            ->with('schedule')
            ->firstOrFail();

        $request->validate([
            'subject_id' => 'sometimes|exists:subjects,id',
            'teacher_id' => 'sometimes|exists:teachers,id',
            'dayofweek'  => 'sometimes|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'starttime'  => 'sometimes|date_format:H:i',
        ]);

        $teacherId = $request->input('teacher_id', $slot->teacher_id);
        $dayofweek = $request->input('dayofweek', $slot->dayofweek);
        $starttime = $request->input('starttime', $slot->starttime);

        // Only check conflicts if something relevant changed
        if ($teacherId != $slot->teacher_id || $dayofweek != $slot->dayofweek || $starttime != $slot->starttime) {
            $conflicts = $this->detectConflicts(
                $teacherId,
                $slot->schedule->section_id,
                $dayofweek,
                $starttime,
                $slotId
            );
            if ($conflicts) {
                return response()->json(['message' => $conflicts], 422);
            }
        }

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

    // ─────────────────────────────────────────────
    // CONFLICT DETECTION
    // ─────────────────────────────────────────────

    private function detectConflicts(int $teacherId, int $sectionId, string $dayofweek, string $starttime, ?int $excludeSlotId = null): ?string
    {
        // 1. Teacher double-booking: same teacher, same day+time, any section
        $teacherConflict = ScheduleSlot::where('teacher_id', $teacherId)
            ->where('dayofweek', $dayofweek)
            ->where('starttime', $starttime)
            ->when($excludeSlotId, fn ($q) => $q->where('slot_id', '!=', $excludeSlotId))
            ->with('schedule.section')
            ->first();

        if ($teacherConflict) {
            $sectionName = $teacherConflict->schedule?->section?->name ?? 'another section';
            return "Teacher is already scheduled on {$dayofweek} at {$starttime} in {$sectionName}.";
        }

        // 2. Section double-booking: same section, same day+time
        $sectionConflict = ScheduleSlot::whereHas('schedule', fn ($q) => $q->where('section_id', $sectionId))
            ->where('dayofweek', $dayofweek)
            ->where('starttime', $starttime)
            ->when($excludeSlotId, fn ($q) => $q->where('slot_id', '!=', $excludeSlotId))
            ->first();

        if ($sectionConflict) {
            return "This section already has a slot on {$dayofweek} at {$starttime}.";
        }

        return null;
    }
}
