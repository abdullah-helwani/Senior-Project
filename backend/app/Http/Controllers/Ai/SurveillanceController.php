<?php

namespace App\Http\Controllers\Ai;

use App\Http\Controllers\Controller;
use App\Models\SurveillanceEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SurveillanceController extends Controller
{
    /**
     * POST /ai/surveillance-events
     *
     * Receive surveillance events from the AI module.
     * Accepts a single event or a batch of events.
     *
     * Single event body:
     *   camera_id, detectedtype, severity, relatedstudent_id?, relatedsection_id?, relatedassessment_id?
     *
     * Batch body:
     *   events: [ { camera_id, detectedtype, severity, ... }, ... ]
     */
    public function store(Request $request)
    {
        // Batch mode
        if ($request->has('events')) {
            $request->validate([
                'events'                        => 'required|array|min:1',
                'events.*.camera_id'            => 'required|integer|exists:camera,camera_id',
                'events.*.detectedtype'         => 'required|string|max:255',
                'events.*.severity'             => 'required|in:low,medium,high,critical',
                'events.*.relatedstudent_id'    => 'nullable|integer|exists:students,id',
                'events.*.relatedsection_id'    => 'nullable|integer|exists:section,section_id',
                'events.*.relatedassessment_id' => 'nullable|integer|exists:assessment,assessment_id',
            ]);

            $inserted = DB::transaction(function () use ($request) {
                $events = [];
                foreach ($request->events as $eventData) {
                    $events[] = SurveillanceEvent::create([
                        'camera_id'            => $eventData['camera_id'],
                        'detectedtype'         => $eventData['detectedtype'],
                        'detectedat'           => now(),
                        'severity'             => $eventData['severity'],
                        'relatedstudent_id'    => $eventData['relatedstudent_id'] ?? null,
                        'relatedsection_id'    => $eventData['relatedsection_id'] ?? null,
                        'relatedassessment_id' => $eventData['relatedassessment_id'] ?? null,
                    ]);
                }
                return $events;
            });

            return response()->json([
                'message' => count($inserted) . ' surveillance event(s) recorded.',
                'events'  => $inserted,
            ], 201);
        }

        // Single event mode
        $data = $request->validate([
            'camera_id'            => 'required|integer|exists:camera,camera_id',
            'detectedtype'         => 'required|string|max:255',
            'severity'             => 'required|in:low,medium,high,critical',
            'relatedstudent_id'    => 'nullable|integer|exists:students,id',
            'relatedsection_id'    => 'nullable|integer|exists:section,section_id',
            'relatedassessment_id' => 'nullable|integer|exists:assessment,assessment_id',
        ]);

        $event = SurveillanceEvent::create([
            'camera_id'            => $data['camera_id'],
            'detectedtype'         => $data['detectedtype'],
            'detectedat'           => now(),
            'severity'             => $data['severity'],
            'relatedstudent_id'    => $data['relatedstudent_id'] ?? null,
            'relatedsection_id'    => $data['relatedsection_id'] ?? null,
            'relatedassessment_id' => $data['relatedassessment_id'] ?? null,
        ]);

        return response()->json($event, 201);
    }
}
