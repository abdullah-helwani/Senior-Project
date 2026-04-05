<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\RouteStop;
use App\Models\StudentBusAssignment;
use Illuminate\Http\Request;

class StudentBusAssignmentController extends Controller
{
    /**
     * List student↔bus assignments.
     * Filters: ?student_id, ?bus_id, ?route_id
     */
    public function index(Request $request)
    {
        $query = StudentBusAssignment::with([
            'student.user',
            'bus',
            'route',
            'stop',
        ]);

        foreach (['student_id', 'bus_id', 'route_id'] as $field) {
            if ($request->filled($field)) {
                $query->where($field, $request->input($field));
            }
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->paginate($perPage));
    }

    public function store(Request $request)
    {
        $request->validate([
            'student_id' => 'required|integer|exists:students,id',
            'bus_id'     => 'required|integer|exists:bus,bus_id',
            'route_id'   => 'required|integer|exists:route,route_id',
            'stop_id'    => 'required|integer|exists:routestop,stop_id',
        ]);

        // Ensure the stop actually belongs to the chosen route
        $stopBelongsToRoute = RouteStop::where('stop_id', $request->stop_id)
            ->where('route_id', $request->route_id)
            ->exists();

        if (! $stopBelongsToRoute) {
            return response()->json([
                'message' => 'The selected stop does not belong to the selected route.',
            ], 422);
        }

        // One active assignment per student
        $existing = StudentBusAssignment::where('student_id', $request->student_id)->exists();
        if ($existing) {
            return response()->json([
                'message' => 'This student already has a bus assignment. Update or delete the existing one first.',
            ], 422);
        }

        $assignment = StudentBusAssignment::create(
            $request->only('student_id', 'bus_id', 'route_id', 'stop_id')
        );

        return response()->json(
            $assignment->load(['student.user', 'bus', 'route', 'stop']),
            201
        );
    }

    public function show(int $id)
    {
        return response()->json(
            StudentBusAssignment::with(['student.user', 'bus', 'route', 'stop'])->findOrFail($id)
        );
    }

    public function update(Request $request, int $id)
    {
        $assignment = StudentBusAssignment::findOrFail($id);

        $request->validate([
            'bus_id'   => 'sometimes|integer|exists:bus,bus_id',
            'route_id' => 'sometimes|integer|exists:route,route_id',
            'stop_id'  => 'sometimes|integer|exists:routestop,stop_id',
        ]);

        $routeId = $request->input('route_id', $assignment->route_id);
        $stopId  = $request->input('stop_id', $assignment->stop_id);

        $stopBelongsToRoute = RouteStop::where('stop_id', $stopId)
            ->where('route_id', $routeId)
            ->exists();

        if (! $stopBelongsToRoute) {
            return response()->json([
                'message' => 'The selected stop does not belong to the selected route.',
            ], 422);
        }

        $assignment->update($request->only('bus_id', 'route_id', 'stop_id'));

        return response()->json($assignment->load(['student.user', 'bus', 'route', 'stop']));
    }

    public function destroy(int $id)
    {
        StudentBusAssignment::findOrFail($id)->delete();

        return response()->json(['message' => 'Student bus assignment removed.']);
    }
}
