<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\TeacherAvailability;
use Illuminate\Http\Request;

class AvailabilityController extends Controller
{
    /**
     * GET /teacher/{teacherId}/availability
     *
     * List this teacher's availability slots. Filters: dayofweek
     */
    public function index(int $teacherId, Request $request)
    {
        $query = TeacherAvailability::where('teacher_id', $teacherId);

        if ($request->filled('dayofweek')) {
            $query->where('dayofweek', $request->dayofweek);
        }

        $slots = $query->orderByRaw("CASE dayofweek
                WHEN 'Sunday' THEN 1 WHEN 'Monday' THEN 2 WHEN 'Tuesday' THEN 3
                WHEN 'Wednesday' THEN 4 WHEN 'Thursday' THEN 5 WHEN 'Friday' THEN 6
                WHEN 'Saturday' THEN 7 END")
            ->orderBy('start_time')
            ->get();

        return response()->json([
            'teacher_id' => $teacherId,
            'count'      => $slots->count(),
            'slots'      => $slots,
        ]);
    }

    /**
     * POST /teacher/{teacherId}/availability
     *
     * Add an availability slot.
     */
    public function store(int $teacherId, Request $request)
    {
        $data = $request->validate([
            'dayofweek'        => 'required|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'start_time'       => 'required|date_format:H:i',
            'end_time'         => 'required|date_format:H:i|after:start_time',
            'availabilitytype' => 'required|in:available,unavailable,preferred',
        ]);

        $slot = TeacherAvailability::create([
            'teacher_id'       => $teacherId,
            'dayofweek'        => $data['dayofweek'],
            'start_time'       => $data['start_time'],
            'end_time'         => $data['end_time'],
            'availabilitytype' => $data['availabilitytype'],
        ]);

        return response()->json($slot, 201);
    }

    /**
     * PUT /teacher/{teacherId}/availability/{id}
     */
    public function update(int $teacherId, int $id, Request $request)
    {
        $slot = TeacherAvailability::where('teacher_id', $teacherId)
            ->where('availability_id', $id)
            ->firstOrFail();

        $data = $request->validate([
            'dayofweek'        => 'sometimes|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'start_time'       => 'sometimes|date_format:H:i',
            'end_time'         => 'sometimes|date_format:H:i',
            'availabilitytype' => 'sometimes|in:available,unavailable,preferred',
        ]);

        $slot->update($data);

        return response()->json($slot);
    }

    /**
     * DELETE /teacher/{teacherId}/availability/{id}
     */
    public function destroy(int $teacherId, int $id)
    {
        TeacherAvailability::where('teacher_id', $teacherId)
            ->where('availability_id', $id)
            ->firstOrFail()
            ->delete();

        return response()->json(['message' => 'Availability slot removed successfully.']);
    }
}
