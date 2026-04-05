<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\RouteStop;
use App\Models\StudentBusAssignment;
use App\Models\Trip;
use App\Models\TripStopEvent;
use Illuminate\Http\Request;

class StopEventController extends Controller
{
    /**
     * List all stop events for one of this driver's trips
     * (e.g. driver opens trip and sees who has already been picked up / dropped off).
     */
    public function index(int $driverId, int $tripId)
    {
        $trip = Trip::where('trip_id', $tripId)
            ->where('driver_id', $driverId)
            ->firstOrFail();

        $events = TripStopEvent::with(['stop', 'student.user'])
            ->where('trip_id', $trip->trip_id)
            ->orderBy('eventat')
            ->get();

        return response()->json($events);
    }

    /**
     * Driver presses a button → log a student boarding or drop-off at a stop.
     */
    public function store(Request $request, int $driverId, int $tripId)
    {
        $trip = Trip::where('trip_id', $tripId)
            ->where('driver_id', $driverId)
            ->firstOrFail();

        $request->validate([
            'student_id' => 'required|integer|exists:students,id',
            'stop_id'    => 'required|integer|exists:routestop,stop_id',
            'eventtype'  => 'required|in:boarded,dropped',
            'eventat'    => 'nullable|date',
        ]);

        // The stop must belong to the trip's route
        $stopValid = RouteStop::where('stop_id', $request->stop_id)
            ->where('route_id', $trip->route_id)
            ->exists();
        if (! $stopValid) {
            return response()->json([
                'message' => 'This stop does not belong to the trip\'s route.',
            ], 422);
        }

        // The student must be assigned to this bus + route
        $studentValid = StudentBusAssignment::where('student_id', $request->student_id)
            ->where('bus_id', $trip->bus_id)
            ->where('route_id', $trip->route_id)
            ->exists();
        if (! $studentValid) {
            return response()->json([
                'message' => 'This student is not assigned to this bus/route.',
            ], 422);
        }

        $event = TripStopEvent::create([
            'trip_id'    => $trip->trip_id,
            'stop_id'    => $request->stop_id,
            'student_id' => $request->student_id,
            'eventtype'  => $request->eventtype,
            'eventat'    => $request->eventat ?? now(),
        ]);

        return response()->json($event->load(['stop', 'student.user']), 201);
    }
}
