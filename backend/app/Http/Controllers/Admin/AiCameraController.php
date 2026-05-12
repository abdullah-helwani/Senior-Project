<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Camera;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Client\ConnectionException;

class AiCameraController extends Controller
{
    /**
     * POST /admin/ai-cameras/{id}/start
     *
     * Tell KIRA to start monitoring a camera. Saves the returned stream_id
     * on the camera row so subsequent stop calls can reference it.
     */
    public function start(Request $request, int $id)
    {
        $camera = Camera::where('camera_id', $id)->firstOrFail();

        $data = $request->validate([
            'camera_url' => 'required|string',
        ]);

        try {
            $response = $this->kira()->post('/stream/start', [
                'camera_url' => $data['camera_url'],
                'camera_id'  => $camera->code ?? "camera-{$id}",
            ]);
        } catch (ConnectionException) {
            return response()->json(['error' => 'Cannot reach the AI service. Is KIRA running on port 8001?'], 502);
        }

        if ($response->successful()) {
            $body = $response->json();
            $camera->update([
                'stream_id'  => $body['stream_id'] ?? null,
                'stream_url' => $data['camera_url'],
            ]);
            return response()->json($body, 200);
        }

        return $this->kiraError($response);
    }

    /**
     * POST /admin/ai-cameras/{id}/stop
     *
     * Tell KIRA to stop monitoring a camera. Clears the stream_id on success
     * and also on 404 (stream already gone, e.g. after KIRA restart) and on
     * ConnectionException (KIRA is down) so the dashboard always reflects reality.
     */
    public function stop(int $id)
    {
        $camera = Camera::where('camera_id', $id)->firstOrFail();

        if (!$camera->stream_id) {
            return response()->json(['error' => 'This camera is not currently streaming.'], 422);
        }

        try {
            $response = $this->kira()->post('/stream/stop', [
                'stream_id' => $camera->stream_id,
            ]);
        } catch (ConnectionException) {
            // KIRA is unreachable — clear the stale record so the dashboard syncs
            $camera->update(['stream_id' => null]);
            return response()->json(['message' => 'AI service is offline. Stream state cleared.'], 200);
        }

        if ($response->successful()) {
            $camera->update(['stream_id' => null]);
            return response()->json($response->json(), 200);
        }

        // 404 means KIRA no longer knows about this stream (e.g. after a restart).
        // Clear our record so the dashboard reflects reality.
        if ($response->status() === 404) {
            $camera->update(['stream_id' => null]);
            return response()->json(['message' => 'Stream not found in AI service — state cleared.'], 200);
        }

        return $this->kiraError($response);
    }

    /**
     * POST /admin/ai-cameras/sync
     *
     * Reconcile DB stream_ids against KIRA's live stream list.
     * Clears stream_id for any camera whose stream is no longer running in KIRA.
     * If KIRA is offline, clears all stream_ids.
     */
    public function sync()
    {
        try {
            $response = $this->kira()->get('/stream/list');
        } catch (ConnectionException) {
            $cleared = Camera::whereNotNull('stream_id')->update(['stream_id' => null]);
            return response()->json([
                'message' => "KIRA is offline. Cleared {$cleared} stale stream(s).",
                'cleared' => $cleared,
            ]);
        }

        if (!$response->successful()) {
            return $this->kiraError($response);
        }

        $liveStreamIds = collect($response->json())
            ->pluck('stream_id')
            ->filter()
            ->values();

        $cleared = Camera::whereNotNull('stream_id')
            ->whereNotIn('stream_id', $liveStreamIds->toArray())
            ->update(['stream_id' => null]);

        return response()->json([
            'message'      => "Synced. Cleared {$cleared} stale stream(s).",
            'live_streams' => $liveStreamIds->count(),
            'cleared'      => $cleared,
        ]);
    }

    /**
     * GET /admin/ai-cameras/streams
     *
     * List all active streams from KIRA.
     */
    public function streams()
    {
        $response = $this->kira()->get('/stream/list');

        if ($response->successful()) {
            return response()->json($response->json(), 200);
        }

        return $this->kiraError($response);
    }

    /**
     * GET /admin/ai-cameras/health
     *
     * Ping KIRA health endpoint (no API key required on the KIRA side).
     */
    public function health()
    {
        try {
            $response = Http::timeout(5)->get(config('services.kira.base_url') . '/health');
            return response()->json($response->json(), 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'down', 'error' => $e->getMessage()], 502);
        }
    }

    /**
     * Translate KIRA error responses into safe 4xx/5xx codes that won't
     * trigger the frontend's 401-logout interceptor.
     */
    private function kiraError(\Illuminate\Http\Client\Response $response)
    {
        $status = $response->status();

        // Never forward 401 — it would log the admin user out of the dashboard
        if ($status === 401 || $status === 403) {
            return response()->json([
                'error' => 'AI service rejected the request (API key mismatch). Check KIRA_API_KEY in .env.',
            ], 502);
        }

        // Map any other KIRA error to 502 so the frontend knows it's a downstream failure
        return response()->json([
            'error'  => 'AI service returned an error.',
            'detail' => $response->json('detail') ?? $response->body(),
        ], 502);
    }

    private function kira()
    {
        return Http::withHeaders(['X-API-Key' => config('services.kira.api_key')])
                   ->baseUrl(config('services.kira.base_url'))
                   ->timeout(10);
    }
}
