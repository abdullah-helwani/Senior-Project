<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\NotificationRecipient;
use App\Models\Student;
use Illuminate\Http\Request;

class WarningController extends Controller
{
    /**
     * GET /student/{studentId}/warnings
     *
     * Returns warnings sent to this student (notifications with channel = 'warning').
     */
    public function index(int $studentId, Request $request)
    {
        $student = Student::with('user')->findOrFail($studentId);

        $query = NotificationRecipient::where('user_id', $student->user_id)
            ->whereHas('notification', fn ($q) => $q->where('channel', 'warning'))
            ->with(['notification.createdBy']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $warnings = $query->orderByDesc('recipient_id')
            ->paginate($request->input('per_page', 20));

        $unreadCount = NotificationRecipient::where('user_id', $student->user_id)
            ->where('status', 'unread')
            ->whereHas('notification', fn ($q) => $q->where('channel', 'warning'))
            ->count();

        return response()->json([
            'unread_count' => $unreadCount,
            'warnings'     => $warnings,
        ]);
    }
}
