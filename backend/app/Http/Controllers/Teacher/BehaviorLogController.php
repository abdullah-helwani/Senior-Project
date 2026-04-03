<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\BehaviorLog;
use App\Models\Notification;
use App\Models\NotificationRecipient;
use App\Models\Student;
use App\Models\StudentGuardian;
use App\Models\Teacher;
use Illuminate\Http\Request;

class BehaviorLogController extends Controller
{
    /**
     * GET /teacher/{teacherId}/behavior-logs
     *
     * List behavior logs created by this teacher.
     * Filters: section_id, student_id, type (positive/negative/neutral), from, to
     */
    public function index(int $teacherId, Request $request)
    {
        $query = BehaviorLog::where('teacher_id', $teacherId)
            ->with(['student', 'section']);

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('from')) {
            $query->where('date', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('date', '<=', $request->to);
        }

        $logs = $query->orderByDesc('date')
            ->paginate($request->input('per_page', 20));

        return response()->json($logs);
    }

    /**
     * POST /teacher/{teacherId}/behavior-logs
     *
     * Create a behavior log entry.
     * If notify_parent = true, a warning notification is sent to the student's parent(s).
     */
    public function store(int $teacherId, Request $request)
    {
        $teacher = Teacher::with('user')->findOrFail($teacherId);

        $request->validate([
            'student_id'    => 'required|exists:students,id',
            'section_id'    => 'required|integer',
            'type'          => 'required|in:positive,negative,neutral',
            'title'         => 'required|string|max:255',
            'description'   => 'nullable|string',
            'date'          => 'required|date',
            'notify_parent' => 'sometimes|boolean',
        ]);

        $log = BehaviorLog::create([
            'student_id'    => $request->student_id,
            'teacher_id'    => $teacherId,
            'section_id'    => $request->section_id,
            'type'          => $request->type,
            'title'         => $request->title,
            'description'   => $request->description,
            'date'          => $request->date,
            'notify_parent' => $request->boolean('notify_parent', false),
        ]);

        // If notify_parent, send a warning notification to the student + parent(s)
        if ($log->notify_parent) {
            $student = Student::with('user')->find($request->student_id);

            $notification = Notification::create([
                'title'          => "Behavior report for {$student->user->name}: {$log->title}",
                'createdbyuserid' => $teacher->user_id,
                'channel'        => 'warning',
                'created_at'     => now(),
            ]);

            // Notify the student
            NotificationRecipient::create([
                'notification_id' => $notification->notification_id,
                'user_id'         => $student->user_id,
                'status'          => 'unread',
                'deliveredat'     => now(),
            ]);

            // Notify all linked parents
            $parentLinks = StudentGuardian::where('student_id', $request->student_id)->get();
            foreach ($parentLinks as $link) {
                $guardian = $link->guardian;
                if ($guardian) {
                    NotificationRecipient::create([
                        'notification_id' => $notification->notification_id,
                        'user_id'         => $guardian->user_id,
                        'status'          => 'unread',
                        'deliveredat'     => now(),
                    ]);
                }
            }
        }

        return response()->json($log->load(['student', 'section']), 201);
    }

    /**
     * GET /teacher/{teacherId}/behavior-logs/{logId}
     */
    public function show(int $teacherId, int $logId)
    {
        $log = BehaviorLog::where('teacher_id', $teacherId)
            ->where('log_id', $logId)
            ->with(['student', 'section'])
            ->firstOrFail();

        return response()->json($log);
    }
}
