<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AttendanceSession;
use App\Models\Enrollment;
use App\Models\StudentAttendance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    /**
     * GET /admin/attendance
     *
     * List attendance sessions. Filters: section_id, from, to
     */
    public function index(Request $request)
    {
        $query = AttendanceSession::with('section.schoolClass');

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('from')) {
            $query->where('date', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('date', '<=', $request->to);
        }

        $sessions = $query->orderByDesc('date')
            ->paginate($request->input('per_page', 20));

        return response()->json($sessions);
    }

    /**
     * GET /admin/attendance/{sessionId}
     *
     * View a single session with all student records.
     */
    public function show(int $sessionId)
    {
        $session = AttendanceSession::where('session_id', $sessionId)
            ->with('section.schoolClass')
            ->firstOrFail();

        $records = StudentAttendance::where('session_id', $sessionId)
            ->with('student.user')
            ->get();

        $summary = [
            'present' => $records->where('status', 'present')->count(),
            'absent'  => $records->where('status', 'absent')->count(),
            'late'    => $records->where('status', 'late')->count(),
            'excused' => $records->where('status', 'excused')->count(),
        ];

        return response()->json([
            'session'  => $session,
            'summary'  => $summary,
            'students' => $records->map(fn ($r) => [
                'attendance_id' => $r->attendance_id,
                'student_id'    => $r->student_id,
                'name'          => $r->student->user->name,
                'status'        => $r->status,
            ]),
        ]);
    }

    /**
     * POST /admin/attendance
     *
     * Record attendance for a section on a date.
     */
    public function store(Request $request)
    {
        $request->validate([
            'section_id'           => 'required|integer',
            'date'                 => 'required|date',
            'records'              => 'required|array|min:1',
            'records.*.student_id' => 'required|integer',
            'records.*.status'     => 'required|in:present,absent,late,excused',
        ]);

        $adminUserId = $request->user()->id;

        return DB::transaction(function () use ($request, $adminUserId) {
            $session = AttendanceSession::firstOrCreate([
                'section_id' => $request->section_id,
                'date'       => $request->date,
            ]);

            $inserted = 0;
            $updated = 0;

            foreach ($request->records as $record) {
                $existing = StudentAttendance::where('session_id', $session->session_id)
                    ->where('student_id', $record['student_id'])
                    ->first();

                if ($existing) {
                    $existing->update([
                        'status'           => $record['status'],
                        'capturedbyuserid' => $adminUserId,
                    ]);
                    $updated++;
                } else {
                    StudentAttendance::create([
                        'session_id'       => $session->session_id,
                        'student_id'       => $record['student_id'],
                        'status'           => $record['status'],
                        'capturedbyuserid' => $adminUserId,
                    ]);
                    $inserted++;
                }
            }

            return response()->json([
                'message'    => 'Attendance recorded successfully.',
                'session_id' => $session->session_id,
                'date'       => $session->date,
                'inserted'   => $inserted,
                'updated'    => $updated,
            ], 201);
        });
    }

    /**
     * PUT /admin/attendance/{sessionId}/records/{attendanceId}
     *
     * Update a single student's attendance record.
     */
    public function updateRecord(int $sessionId, int $attendanceId, Request $request)
    {
        $record = StudentAttendance::where('session_id', $sessionId)
            ->where('attendance_id', $attendanceId)
            ->firstOrFail();

        $request->validate([
            'status' => 'required|in:present,absent,late,excused',
        ]);

        $record->update([
            'status'           => $request->status,
            'capturedbyuserid' => $request->user()->id,
        ]);

        return response()->json([
            'message'       => 'Attendance record updated.',
            'attendance_id' => $record->attendance_id,
            'status'        => $record->status,
        ]);
    }

    /**
     * DELETE /admin/attendance/{sessionId}
     *
     * Delete an entire attendance session and its records.
     */
    public function destroy(int $sessionId)
    {
        $session = AttendanceSession::where('session_id', $sessionId)->firstOrFail();

        StudentAttendance::where('session_id', $sessionId)->delete();
        $session->delete();

        return response()->json(['message' => 'Attendance session deleted successfully.']);
    }

    /**
     * GET /admin/attendance/student/{studentId}
     *
     * View a student's attendance summary across all sections.
     * Filters: section_id, from, to
     */
    public function studentSummary(int $studentId, Request $request)
    {
        $sessionsQuery = AttendanceSession::query();

        if ($request->filled('section_id')) {
            $sessionsQuery->where('section_id', $request->section_id);
        }

        if ($request->filled('from')) {
            $sessionsQuery->where('date', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $sessionsQuery->where('date', '<=', $request->to);
        }

        $sessionIds = $sessionsQuery->pluck('session_id');

        $records = StudentAttendance::where('student_id', $studentId)
            ->whereIn('session_id', $sessionIds)
            ->with('session')
            ->get();

        $totalSessions = $sessionIds->count();
        $presentCount  = $records->where('status', 'present')->count();
        $absentCount   = $records->where('status', 'absent')->count();
        $lateCount     = $records->where('status', 'late')->count();
        $excusedCount  = $records->where('status', 'excused')->count();

        $percentage = $totalSessions > 0
            ? round((($presentCount + $lateCount) / $totalSessions) * 100, 2)
            : 0;

        return response()->json([
            'student_id'      => $studentId,
            'total_sessions'  => $totalSessions,
            'present'         => $presentCount,
            'absent'          => $absentCount,
            'late'            => $lateCount,
            'excused'         => $excusedCount,
            'percentage'      => $percentage,
        ]);
    }
}
