<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use App\Models\Notification;
use App\Models\NotificationRecipient;
use App\Models\StudentGuardian;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    /**
     * GET /admin/notifications
     *
     * List all notifications. Filters: channel
     */
    public function index(Request $request)
    {
        $query = Notification::with('createdBy');

        if ($request->filled('channel')) {
            $query->where('channel', $request->channel);
        }

        $notifications = $query->orderByDesc('created_at')
            ->paginate($request->input('per_page', 20));

        return response()->json($notifications);
    }

    /**
     * GET /admin/notifications/{id}
     *
     * View a notification with its recipient delivery/read stats.
     */
    public function show(int $id)
    {
        $notification = Notification::where('notification_id', $id)
            ->with('createdBy')
            ->firstOrFail();

        $recipients = NotificationRecipient::where('notification_id', $id)
            ->with('user')
            ->get();

        $stats = [
            'total'     => $recipients->count(),
            'unread'    => $recipients->where('status', 'unread')->count(),
            'read'      => $recipients->where('status', 'read')->count(),
            'delivered' => $recipients->where('status', 'delivered')->count(),
        ];

        return response()->json([
            'notification' => $notification,
            'stats'        => $stats,
            'recipients'   => $recipients->map(fn ($r) => [
                'recipient_id' => $r->recipient_id,
                'user_id'      => $r->user_id,
                'name'         => $r->user->name,
                'role'         => $r->user->role_type,
                'status'       => $r->status,
                'readat'       => $r->readat,
            ]),
        ]);
    }

    /**
     * POST /admin/notifications
     *
     * Create and broadcast a notification.
     *
     * Targeting options (pick one or combine):
     *   - "user_ids": [1, 2, 3]          → specific users
     *   - "roles": ["student", "parent"]  → all users with these roles
     *   - "section_id": 1                 → all students in section (+ optionally their parents)
     *   - "include_parents": true         → when using section_id, also notify parents
     */
    public function store(Request $request)
    {
        $request->validate([
            'title'           => 'required|string|max:255',
            'body'            => 'nullable|string',
            'channel'         => 'required|string|max:50',
            'user_ids'        => 'sometimes|array',
            'user_ids.*'      => 'integer|exists:users,id',
            'roles'           => 'sometimes|array',
            'roles.*'         => 'in:admin,student,teacher,parent,driver',
            'section_id'      => 'sometimes|integer',
            'include_parents' => 'sometimes|boolean',
        ]);

        $notification = DB::transaction(function () use ($request) {
            $notification = Notification::create([
                'title'           => $request->title,
                'body'            => $request->body ?? null,
                'createdbyuserid' => $request->user()->id,
                'channel'         => $request->channel,
                'created_at'      => now(),
            ]);

            $userIds = collect();

            // Specific user IDs
            if ($request->filled('user_ids')) {
                $userIds = $userIds->merge($request->user_ids);
            }

            // By role
            if ($request->filled('roles')) {
                $roleUserIds = User::whereIn('role_type', $request->roles)
                    ->where('is_active', true)
                    ->pluck('id');
                $userIds = $userIds->merge($roleUserIds);
            }

            // By section
            if ($request->filled('section_id')) {
                $enrollments = Enrollment::where('section_id', $request->section_id)
                    ->where('status', 'active')
                    ->with('student')
                    ->get();

                $studentUserIds = $enrollments->map(fn ($e) => $e->student->user_id);
                $userIds = $userIds->merge($studentUserIds);

                // Include parents of those students
                if ($request->boolean('include_parents', false)) {
                    $studentIds = $enrollments->pluck('student_id');
                    $parentLinks = StudentGuardian::whereIn('student_id', $studentIds)
                        ->with('guardian')
                        ->get();
                    $parentUserIds = $parentLinks->map(fn ($l) => $l->guardian->user_id)->filter();
                    $userIds = $userIds->merge($parentUserIds);
                }
            }

            // Deduplicate and create recipients
            $userIds = $userIds->unique()->values();

            $recipients = $userIds->map(fn ($uid) => [
                'notification_id' => $notification->notification_id,
                'user_id'         => $uid,
                'status'          => 'unread',
                'deliveredat'     => now(),
                'readat'          => null,
            ])->toArray();

            DB::table('notificationrecipient')->insert($recipients);

            return $notification;
        });

        return response()->json([
            'notification'    => $notification,
            'recipients_count' => DB::table('notificationrecipient')
                ->where('notification_id', $notification->notification_id)
                ->count(),
        ], 201);
    }

    /**
     * GET /admin/notifications/alerts
     *
     * Return the authenticated admin's unread alert-channel notifications
     * (used by the header bell). Returns up to 20 items + total unread count.
     */
    public function myAlerts(Request $request)
    {
        $userId = $request->user()->id;

        $recipients = NotificationRecipient::where('user_id', $userId)
            ->where('status', 'unread')
            ->whereHas('notification', fn ($q) => $q->where('channel', 'alert'))
            ->with('notification')
            ->orderByDesc('deliveredat')
            ->limit(20)
            ->get();

        return response()->json([
            'unread_count' => $recipients->count(),
            'items'        => $recipients->map(fn ($r) => [
                'recipient_id'    => $r->recipient_id,
                'notification_id' => $r->notification_id,
                'title'           => $r->notification->title,
                'body'            => $r->notification->body,
                'created_at'      => $r->notification->created_at,
                'status'          => $r->status,
            ]),
        ]);
    }

    /**
     * PUT /admin/notifications/alerts/{recipientId}/read
     *
     * Mark one alert recipient record as read.
     */
    public function markOneRead(Request $request, int $recipientId)
    {
        $recipient = NotificationRecipient::where('recipient_id', $recipientId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $recipient->update(['status' => 'read', 'readat' => now()]);

        return response()->json(['message' => 'Marked as read.']);
    }

    /**
     * PUT /admin/notifications/alerts/read-all
     *
     * Mark ALL unread alerts as read for the authenticated admin.
     */
    public function markAllAlertsRead(Request $request)
    {
        NotificationRecipient::where('user_id', $request->user()->id)
            ->where('status', 'unread')
            ->whereHas('notification', fn ($q) => $q->where('channel', 'alert'))
            ->update(['status' => 'read', 'readat' => now()]);

        return response()->json(['message' => 'All alerts marked as read.']);
    }

    /**
     * DELETE /admin/notifications/{id}
     *
     * Delete a notification and all its recipients.
     */
    public function destroy(int $id)
    {
        $notification = Notification::where('notification_id', $id)->firstOrFail();

        NotificationRecipient::where('notification_id', $id)->delete();
        $notification->delete();

        return response()->json(['message' => 'Notification deleted successfully.']);
    }
}
