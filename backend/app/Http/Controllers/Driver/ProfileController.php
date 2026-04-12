<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\Driver;

class ProfileController extends Controller
{
    /**
     * Return the driver's profile: user info, assigned bus(es), and the routes
     * they currently drive (derived from their trips).
     */
    public function show(int $driverId)
    {
        $driver = Driver::with([
            'user',
            'assignments.bus',
        ])->findOrFail($driverId);

        // Distinct routes this driver has ever driven (from trips)
        $routes = \App\Models\Trip::with('route')
            ->where('driver_id', $driverId)
            ->get()
            ->pluck('route')
            ->unique('route_id')
            ->values();

        return response()->json([
            'driver' => $driver,
            'routes' => $routes,
        ]);
    }
}
