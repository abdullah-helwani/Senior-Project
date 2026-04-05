<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\StudentBusAssignment;
use App\Models\Trip;
use Illuminate\Http\Request;

class TripController extends Controller
{
    /**
     * List all trips for this driver. Filters: ?date, ?type
     */
    public function index(Request $request, int $driverId)
    {
        $query = Trip::with(['bus', 'route'])
            ->where('driver_id', $driverId);

        if ($request->filled('date')) {
            $query->whereDate('date', $request->date);
        }
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        return response()->json(
            $query->orderByDesc('date')->orderBy('type')->get()
        );
    }

    /**
     * Today's trips for this driver.
     */
    public function today(int $driverId)
    {
        $trips = Trip::with(['bus', 'route.stops'])
            ->where('driver_id', $driverId)
            ->whereDate('date', now()->toDateString())
            ->orderBy('type')
            ->get();

        return response()->json($trips);
    }

    /**
     * Full details for a specific trip:
     * bus, route, ordered stops, and the students assigned to that route.
     */
    public function show(int $driverId, int $tripId)
    {
        $trip = Trip::with([
            'bus',
            'route.stops',
        ])
            ->where('driver_id', $driverId)
            ->where('trip_id', $tripId)
            ->firstOrFail();

        // Students assigned to this route (who the driver is carrying)
        $students = StudentBusAssignment::with(['student.user', 'stop'])
            ->where('route_id', $trip->route_id)
            ->where('bus_id', $trip->bus_id)
            ->get();

        return response()->json([
            'trip'     => $trip,
            'students' => $students,
        ]);
    }
}
