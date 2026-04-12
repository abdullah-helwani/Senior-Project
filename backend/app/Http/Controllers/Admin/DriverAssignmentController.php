<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DriverAssignment;
use Illuminate\Http\Request;

class DriverAssignmentController extends Controller
{
    /**
     * List all driver↔bus assignments.
     * Filters: ?driver_id, ?bus_id
     */
    public function index(Request $request)
    {
        $query = DriverAssignment::with(['driver.user', 'bus']);

        if ($request->filled('driver_id')) {
            $query->where('driver_id', $request->driver_id);
        }

        if ($request->filled('bus_id')) {
            $query->where('bus_id', $request->bus_id);
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->paginate($perPage));
    }

    public function store(Request $request)
    {
        $request->validate([
            'driver_id' => 'required|integer|exists:driver,driver_id',
            'bus_id'    => 'required|integer|exists:bus,bus_id',
        ]);

        // Prevent duplicate driver↔bus pairs
        $exists = DriverAssignment::where('driver_id', $request->driver_id)
            ->where('bus_id', $request->bus_id)
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'This driver is already assigned to this bus.',
            ], 422);
        }

        $assignment = DriverAssignment::create($request->only('driver_id', 'bus_id'));

        return response()->json($assignment->load(['driver.user', 'bus']), 201);
    }

    public function show(int $id)
    {
        return response()->json(
            DriverAssignment::with(['driver.user', 'bus'])->findOrFail($id)
        );
    }

    public function destroy(int $id)
    {
        DriverAssignment::findOrFail($id)->delete();

        return response()->json(['message' => 'Driver assignment removed.']);
    }
}
