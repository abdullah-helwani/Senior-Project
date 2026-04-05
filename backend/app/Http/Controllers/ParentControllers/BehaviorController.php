<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Guardian;
use App\Models\NotificationRecipient;
use App\Models\Student;
use Illuminate\Http\Request;

class BehaviorController extends Controller
{
    /**
     * GET /parent/{parentId}/children/{studentId}/behavior
     *
     * Returns behavior/warning notifications related to a child.
     * These are notifications with channel = 'warning' sent to the parent's user account.
     */
    public function index(int $parentId, int $studentId, Request $request)
    {
        $guardian = $this->authorizeChild($parentId, $studentId);

        $query = NotificationRecipient::where('user_id', $guardian->user_id)
            ->whereHas('notification', fn ($q) => $q->where('channel', 'warning'))
            ->with(['notification.createdBy']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $warnings = $query->orderByDesc('recipient_id')
            ->paginate($request->input('per_page', 20));

        return response()->json($warnings);
    }

    private function authorizeChild(int $parentId, int $studentId): Guardian
    {
        return Guardian::where('parent_id', $parentId)
            ->whereHas('studentLinks', fn ($q) => $q->where('student_id', $studentId))
            ->firstOrFail();
    }
}
