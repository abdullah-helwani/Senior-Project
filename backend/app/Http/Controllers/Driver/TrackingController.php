<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\TrackingPing;
use App\Models\Trip;
use Illuminate\Http\Request;

class TrackingController extends Controller
{
    /**
     * Record a single GPS ping from the driver's device during a trip.
     */
    public function store(Request $request, int $driverId, int $tripId)
    {
        // Confirm the trip belongs to this driver
        $trip = Trip::where('trip_id', $tripId)
            ->where('driver_id', $driverId)
            ->firstOrFail();

        $request->validate([
            'latitude'   => 'required|numeric|between:-90,90',
            'longitude'  => 'required|numeric|between:-180,180',
            'capturedat' => 'nullable|date',
        ]);

        $ping = TrackingPing::create([
            'trip_id'    => $trip->trip_id,
            'latitude'   => $request->latitude,
            'longitude'  => $request->longitude,
            'capturedat' => $request->capturedat ?? now(),
        ]);

        return response()->json($ping, 201);
    }
}
