<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;

class TripController extends Controller
{
    /**
     * List trips. Filters: ?date, ?driver_id, ?bus_id, ?route_id, ?type
     */
    public function index(Request $request)
    {
        $query = Trip::with(['bus', 'driver.user', 'route']);

        if ($request->filled('date')) {
            $query->whereDate('date', $request->date);
        }
        foreach (['driver_id', 'bus_id', 'route_id', 'type'] as $field) {
            if ($request->filled($field)) {
                $query->where($field, $request->input($field));
            }
        }

        $perPage = $request->input('per_page', 15);

        return response()->json(
            $query->orderByDesc('date')->orderBy('type')->paginate($perPage)
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'bus_id'    => 'required|integer|exists:bus,bus_id',
            'driver_id' => 'required|integer|exists:driver,driver_id',
            'route_id'  => 'required|integer|exists:route,route_id',
            'date'      => 'required|date',
            'type'      => 'required|in:morning,afternoon',
        ]);

        // Prevent duplicate trip (same bus + date + type)
        $duplicate = Trip::where('bus_id', $request->bus_id)
            ->whereDate('date', $request->date)
            ->where('type', $request->type)
            ->exists();

        if ($duplicate) {
            return response()->json([
                'message' => 'A trip already exists for this bus on this date and type.',
            ], 422);
        }

        $trip = Trip::create($request->only('bus_id', 'driver_id', 'route_id', 'date', 'type'));

        return response()->json($trip->load(['bus', 'driver.user', 'route']), 201);
    }

    public function show(int $id)
    {
        $trip = Trip::with([
            'bus',
            'driver.user',
            'route.stops',
        ])->findOrFail($id);

        return response()->json($trip);
    }

    public function update(Request $request, int $id)
    {
        $trip = Trip::findOrFail($id);

        $request->validate([
            'bus_id'    => 'sometimes|integer|exists:bus,bus_id',
            'driver_id' => 'sometimes|integer|exists:driver,driver_id',
            'route_id'  => 'sometimes|integer|exists:route,route_id',
            'date'      => 'sometimes|date',
            'type'      => 'sometimes|in:morning,afternoon',
        ]);

        $trip->update($request->only('bus_id', 'driver_id', 'route_id', 'date', 'type'));

        return response()->json($trip->load(['bus', 'driver.user', 'route']));
    }

    public function destroy(int $id)
    {
        Trip::findOrFail($id)->delete();

        return response()->json(['message' => 'Trip deleted successfully.']);
    }
}
