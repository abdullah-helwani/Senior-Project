<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TeacherAvailability;
use Illuminate\Http\Request;

class TeacherAvailabilityController extends Controller
{
    /**
     * GET /admin/teacher-availability
     *
     * List teacher availability slots. Filters: teacher_id, dayofweek, availabilitytype
     */
    public function index(Request $request)
    {
        $query = TeacherAvailability::with('teacher.user');

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('dayofweek')) {
            $query->where('dayofweek', $request->dayofweek);
        }

        if ($request->filled('availabilitytype')) {
            $query->where('availabilitytype', $request->availabilitytype);
        }

        $slots = $query->orderBy('teacher_id')
            ->orderByRaw("CASE dayofweek
                WHEN 'Sunday' THEN 1 WHEN 'Monday' THEN 2 WHEN 'Tuesday' THEN 3
                WHEN 'Wednesday' THEN 4 WHEN 'Thursday' THEN 5 WHEN 'Friday' THEN 6
                WHEN 'Saturday' THEN 7 END")
            ->orderBy('start_time')
            ->paginate($request->input('per_page', 50));

        return response()->json($slots);
    }

    /**
     * POST /admin/teacher-availability
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'teacher_id'       => 'required|exists:teachers,id',
            'dayofweek'        => 'required|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'start_time'       => 'required|date_format:H:i',
            'end_time'         => 'required|date_format:H:i|after:start_time',
            'availabilitytype' => 'required|in:available,unavailable,preferred',
        ]);

        $slot = TeacherAvailability::create($data);

        return response()->json($slot->load('teacher.user'), 201);
    }

    /**
     * GET /admin/teacher-availability/{id}
     */
    public function show(int $id)
    {
        $slot = TeacherAvailability::where('availability_id', $id)
            ->with('teacher.user')
            ->firstOrFail();

        return response()->json($slot);
    }

    /**
     * PUT /admin/teacher-availability/{id}
     */
    public function update(int $id, Request $request)
    {
        $slot = TeacherAvailability::where('availability_id', $id)->firstOrFail();

        $data = $request->validate([
            'dayofweek'        => 'sometimes|in:Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday',
            'start_time'       => 'sometimes|date_format:H:i',
            'end_time'         => 'sometimes|date_format:H:i',
            'availabilitytype' => 'sometimes|in:available,unavailable,preferred',
        ]);

        $slot->update($data);

        return response()->json($slot->load('teacher.user'));
    }

    /**
     * DELETE /admin/teacher-availability/{id}
     */
    public function destroy(int $id)
    {
        TeacherAvailability::where('availability_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Availability slot removed successfully.']);
    }
}
