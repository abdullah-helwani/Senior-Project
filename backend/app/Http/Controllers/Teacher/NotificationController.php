<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\NotificationRecipient;
use App\Models\Teacher;

class NotificationController extends Controller
{
    public function index(int $teacherId)
    {
        $teacher = Teacher::findOrFail($teacherId);

        $recipients = NotificationRecipient::with('notification')
            ->where('user_id', $teacher->user_id)
            ->orderByDesc('recipient_id')
            ->get();

        $items = $recipients->map(function ($r) {
            $n = $r->notification;
            return [
                'id'         => $r->recipient_id,
                'title'      => $n?->title ?? '',
                'body'       => $n?->body,
                'is_read'    => $r->status === 'read',
                'created_at' => optional($n?->created_at)->toIso8601String()
                                 ?? optional($r->deliveredat)->toIso8601String()
                                 ?? '',
            ];
        })->values();

        $unreadCount = NotificationRecipient::where('user_id', $teacher->user_id)
            ->where('status', 'unread')
            ->count();

        return response()->json([
            'unread_count' => $unreadCount,
            'data'         => $items,
        ]);
    }

    public function markRead(int $teacherId, int $recipientId)
    {
        $teacher = Teacher::findOrFail($teacherId);

        $recipient = NotificationRecipient::where('user_id', $teacher->user_id)
            ->findOrFail($recipientId);

        if ($recipient->status === 'unread') {
            $recipient->update([
                'status' => 'read',
                'readat' => now(),
            ]);
        }

        return response()->json(['message' => 'Notification marked as read.']);
    }

    public function markAllRead(int $teacherId)
    {
        $teacher = Teacher::findOrFail($teacherId);

        NotificationRecipient::where('user_id', $teacher->user_id)
            ->where('status', 'unread')
            ->update([
                'status' => 'read',
                'readat' => now(),
            ]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }
}
