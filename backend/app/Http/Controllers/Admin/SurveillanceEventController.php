<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SurveillanceEvent;
use Illuminate\Http\Request;

class SurveillanceEventController extends Controller
{
    /**
     * GET /admin/surveillance-events
     *
     * List surveillance events.
     * Filters: camera_id, detectedtype, severity, student_id, section_id, from, to
     */
    public function index(Request $request)
    {
        $query = SurveillanceEvent::with(['camera', 'student.user', 'section.schoolClass']);

        if ($request->filled('camera_id')) {
            $query->where('camera_id', $request->camera_id);
        }

        if ($request->filled('detectedtype')) {
            $query->where('detectedtype', $request->detectedtype);
        }

        if ($request->filled('severity')) {
            $query->where('severity', $request->severity);
        }

        if ($request->filled('student_id')) {
            $query->where('relatedstudent_id', $request->student_id);
        }

        if ($request->filled('section_id')) {
            $query->where('relatedsection_id', $request->section_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('from')) {
            $query->where('detectedat', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('detectedat', '<=', $request->to);
        }

        $events = $query->orderByDesc('detectedat')
            ->paginate($request->input('per_page', 20));

        return response()->json($events);
    }

    /**
     * GET /admin/surveillance-events/{id}
     */
    public function show(int $id)
    {
        $event = SurveillanceEvent::where('survevent_id', $id)
            ->with(['camera', 'student.user', 'section.schoolClass', 'assessment'])
            ->firstOrFail();

        return response()->json($event);
    }

    /**
     * GET /admin/surveillance-events/summary
     *
     * Summary stats for a date range. Filters: from (required), to (required), camera_id
     */
    public function summary(Request $request)
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $query = SurveillanceEvent::whereBetween('detectedat', [$request->from, $request->to]);

        if ($request->filled('camera_id')) {
            $query->where('camera_id', $request->camera_id);
        }

        $events = $query->get();

        return response()->json([
            'period'     => ['from' => $request->from, 'to' => $request->to],
            'total'      => $events->count(),
            'by_type'    => $events->groupBy('detectedtype')->map->count(),
            'by_severity' => $events->groupBy('severity')->map->count(),
            'by_camera'  => $events->groupBy('camera_id')->map->count(),
        ]);
    }

    /**
     * PATCH /admin/surveillance-events/{id}/status
     *
     * Mark an event as acknowledged or dismissed.
     */
    public function updateStatus(int $id, Request $request)
    {
        $event = SurveillanceEvent::where('survevent_id', $id)->firstOrFail();

        $data = $request->validate([
            'status' => 'required|in:new,acknowledged,dismissed',
        ]);

        $event->update(['status' => $data['status']]);

        return response()->json($event);
    }

    /**
     * GET /admin/surveillance-footage/{filename}
     *
     * Stream a fight recording file from the KIRA footage directory.
     * Filename is restricted to alphanumerics + dots/dashes/underscores by the route regex.
     */
    public function footage(string $filename)
    {
        $dir      = rtrim(env('KIRA_FOOTAGE_PATH', ''), '/\\');
        $filepath = $dir . DIRECTORY_SEPARATOR . $filename;

        abort_unless(file_exists($filepath), 404, 'Footage file not found.');

        // Serve as a download so the browser hands it off to the native video player
        return response()->download($filepath, $filename);
    }

    /**
     * DELETE /admin/surveillance-events/{id}
     */
    public function destroy(int $id)
    {
        SurveillanceEvent::where('survevent_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Surveillance event deleted successfully.']);
    }
}
