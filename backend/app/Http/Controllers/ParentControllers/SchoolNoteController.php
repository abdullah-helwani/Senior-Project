<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Guardian;
use App\Models\NotificationRecipient;
use Illuminate\Http\Request;

class SchoolNoteController extends Controller
{
    /**
     * GET /parent/{parentId}/notes
     *
     * Returns school notes/notifications sent to this parent.
     * Excludes warnings (those are in behavior endpoint).
     */
    public function index(int $parentId, Request $request)
    {
        $guardian = Guardian::findOrFail($parentId);

        $query = NotificationRecipient::where('user_id', $guardian->user_id)
            ->whereHas('notification', fn ($q) => $q->where('channel', '!=', 'warning'))
            ->with(['notification.createdBy']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $notes = $query->orderByDesc('recipient_id')
            ->paginate($request->input('per_page', 20));

        $unreadCount = NotificationRecipient::where('user_id', $guardian->user_id)
            ->where('status', 'unread')
            ->whereHas('notification', fn ($q) => $q->where('channel', '!=', 'warning'))
            ->count();

        return response()->json([
            'unread_count' => $unreadCount,
            'notes'        => $notes,
        ]);
    }

    /**
     * PUT /parent/{parentId}/notes/{recipientId}/read
     */
    public function markRead(int $parentId, int $recipientId)
    {
        $guardian = Guardian::findOrFail($parentId);

        $recipient = NotificationRecipient::where('recipient_id', $recipientId)
            ->where('user_id', $guardian->user_id)
            ->firstOrFail();

        $recipient->update([
            'status' => 'read',
            'readat' => now(),
        ]);

        return response()->json(['message' => 'Marked as read.']);
    }
}
