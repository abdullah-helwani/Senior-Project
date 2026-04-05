<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentBusAssignment;
use App\Models\TrackingPing;
use App\Models\Trip;
use App\Models\TripStopEvent;
use Illuminate\Http\Request;

class BusController extends Controller
{
    /**
     * Return the student's current bus assignment (bus, route, pickup stop).
     */
    public function assignment(int $studentId)
    {
        $assignment = StudentBusAssignment::with(['bus', 'route.stops', 'stop'])
            ->where('student_id', $studentId)
            ->first();

        if (! $assignment) {
            return response()->json(['message' => 'No bus assignment found.'], 404);
        }

        return response()->json($assignment);
    }

    /**
     * Live location of the student's bus (today's active trip, latest GPS ping).
     */
    public function liveLocation(int $studentId)
    {
        $assignment = StudentBusAssignment::where('student_id', $studentId)->first();
        if (! $assignment) {
            return response()->json(['message' => 'No bus assignment found.'], 404);
        }

        $trip = Trip::with(['driver.user', 'route'])
            ->where('bus_id', $assignment->bus_id)
            ->where('route_id', $assignment->route_id)
            ->whereDate('date', now()->toDateString())
            ->orderByDesc('trip_id')
            ->first();

        if (! $trip) {
            return response()->json(['message' => 'No active trip today.'], 404);
        }

        $location = TrackingPing::where('trip_id', $trip->trip_id)
            ->orderByDesc('capturedat')
            ->first();

        return response()->json([
            'trip'     => $trip,
            'location' => $location,
        ]);
    }

    /**
     * This student's own boarding/dropoff history across all trips.
     * Optional ?from=YYYY-MM-DD&to=YYYY-MM-DD
     */
    public function events(Request $request, int $studentId)
    {
        $query = TripStopEvent::with(['stop', 'trip.route'])
            ->where('student_id', $studentId);

        if ($request->filled('from')) {
            $query->whereDate('eventat', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $query->whereDate('eventat', '<=', $request->to);
        }

        return response()->json(
            $query->orderByDesc('eventat')->paginate($request->input('per_page', 20))
        );
    }
}
