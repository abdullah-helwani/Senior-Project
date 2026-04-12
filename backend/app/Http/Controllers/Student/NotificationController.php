<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\NotificationRecipient;
use App\Models\Student;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(int $studentId, Request $request)
    {
        $student = Student::findOrFail($studentId);

        $query = NotificationRecipient::with('notification')
            ->where('user_id', $student->user_id);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $notifications = $query->orderByDesc('recipient_id')->paginate($request->input('per_page', 20));

        $unreadCount = NotificationRecipient::where('user_id', $student->user_id)
            ->where('status', 'unread')
            ->count();

        return response()->json([
            'unread_count'  => $unreadCount,
            'notifications' => $notifications,
        ]);
    }

    public function markRead(int $studentId, int $recipientId)
    {
        $student = Student::findOrFail($studentId);

        $recipient = NotificationRecipient::where('user_id', $student->user_id)
            ->findOrFail($recipientId);

        if ($recipient->status === 'unread') {
            $recipient->update([
                'status' => 'read',
                'readat' => now(),
            ]);
        }

        return response()->json($recipient->load('notification'));
    }

    public function markAllRead(int $studentId)
    {
        $student = Student::findOrFail($studentId);

        NotificationRecipient::where('user_id', $student->user_id)
            ->where('status', 'unread')
            ->update([
                'status' => 'read',
                'readat' => now(),
            ]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }
}
