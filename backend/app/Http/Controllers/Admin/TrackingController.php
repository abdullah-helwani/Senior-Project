<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TrackingPing;
use App\Models\Trip;
use App\Models\TripStopEvent;

class TrackingController extends Controller
{
    /**
     * Latest known GPS location for a trip.
     */
    public function location(int $tripId)
    {
        $trip = Trip::with(['bus', 'driver.user', 'route'])->findOrFail($tripId);

        $latest = TrackingPing::where('trip_id', $tripId)
            ->orderByDesc('capturedat')
            ->first();

        return response()->json([
            'trip'     => $trip,
            'location' => $latest,
        ]);
    }

    /**
     * Full GPS trail (all pings in order) for a trip.
     */
    public function trail(int $tripId)
    {
        Trip::findOrFail($tripId);

        $pings = TrackingPing::where('trip_id', $tripId)
            ->orderBy('capturedat')
            ->get();

        return response()->json($pings);
    }

    /**
     * All boarding/dropoff events for a trip.
     */
    public function events(int $tripId)
    {
        Trip::findOrFail($tripId);

        $events = TripStopEvent::with(['stop', 'student.user'])
            ->where('trip_id', $tripId)
            ->orderBy('eventat')
            ->get();

        return response()->json($events);
    }
}
