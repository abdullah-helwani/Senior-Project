<?php

namespace App\Http\Controllers\Webhook;

use App\Http\Controllers\Controller;
use App\Models\Camera;
use App\Models\Notification;
use App\Models\SurveillanceEvent;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FightAlertWebhookController extends Controller
{
    /**
     * POST /api/webhooks/fight-alert
     *
     * Receives a fight-detected alert from KIRA (fight-detection AI service).
     * Authenticated by X-API-Key header matched against AI_API_KEY in .env.
     *
     * Expected payload:
     * {
     *   "type":         "fight_detected",
     *   "camera_id":    "hallway-cam-01",   // matches camera.code
     *   "confidence":   0.8731,
     *   "timestamp":    "2026-04-16T10:23:45Z",
     *   "footage_path": "footage/hallway-cam-01_20260416_102345.mp4"
     * }
     */
    public function handle(Request $request)
    {
        if (!$this->validKey($request)) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'type'         => 'required|string',
            'camera_id'    => 'required|string',
            'confidence'   => 'required|numeric|between:0,1',
            'timestamp'    => 'required|date',
            'footage_path' => 'nullable|string|max:512',
        ]);

        $confidence = (float) $data['confidence'];
        $camera     = Camera::where('code', $data['camera_id'])->first();

        $event = DB::transaction(function () use ($data, $confidence, $camera) {
            $event = SurveillanceEvent::create([
                'camera_id'    => $camera?->camera_id,
                'detectedtype' => 'fight',
                'detectedat'   => Carbon::parse($data['timestamp']),
                'severity'     => $this->severityFromConfidence($confidence),
                'confidence'   => $confidence,
                'footage_path' => $data['footage_path'] ?? null,
                'status'       => 'new',
            ]);

            $this->notifyAdmins($camera, $data['camera_id'], $confidence, $data['timestamp']);

            return $event;
        });

        return response()->json([
            'message'  => 'Fight alert recorded.',
            'event_id' => $event->survevent_id,
        ], 201);
    }

    private function validKey(Request $request): bool
    {
        $expected = config('services.kira.webhook_key');
        $provided = $request->header('X-API-Key', '');

        return $expected && hash_equals($expected, $provided);
    }

    private function severityFromConfidence(float $confidence): string
    {
        return match (true) {
            $confidence >= 0.90 => 'critical',
            $confidence >= 0.75 => 'high',
            $confidence >= 0.60 => 'medium',
            default             => 'low',
        };
    }

    private function notifyAdmins(?Camera $camera, string $cameraCode, float $confidence, string $timestamp): void
    {
        $adminIds = User::where('role_type', 'admin')->where('is_active', true)->pluck('id');

        if ($adminIds->isEmpty()) {
            return;
        }

        $location = $camera ? $camera->location : $cameraCode;

        $notification = Notification::create([
            'title'           => "Fight Detected — {$location}",
            'body'            => sprintf(
                'Confidence: %d%% | Camera: %s | Time: %s',
                (int) round($confidence * 100),
                $cameraCode,
                $timestamp
            ),
            'createdbyuserid' => null,
            'channel'         => 'alert',
        ]);

        DB::table('notificationrecipient')->insert(
            $adminIds->map(fn ($uid) => [
                'notification_id' => $notification->notification_id,
                'user_id'         => $uid,
                'status'          => 'unread',
                'deliveredat'     => now(),
                'readat'          => null,
            ])->toArray()
        );
    }
}
