<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\AttendanceSession;
use App\Models\Student;
use App\Models\StudentAttendance;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    /**
     * GET /student/{studentId}/attendance
     *
     * Returns attendance percentage and day-by-day records.
     * Filters: from, to (date range)
     */
    public function index(int $studentId, Request $request)
    {
        $student = Student::with('activeEnrollment')->findOrFail($studentId);

        if (! $student->activeEnrollment) {
            return response()->json(['message' => 'No active enrollment found.'], 404);
        }

        $sectionId = $student->activeEnrollment->section_id;

        // Get all sessions for this section (optionally filtered by date range)
        $sessionsQuery = AttendanceSession::where('section_id', $sectionId);

        if ($request->filled('from')) {
            $sessionsQuery->where('date', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $sessionsQuery->where('date', '<=', $request->to);
        }

        $sessionIds = $sessionsQuery->pluck('session_id');

        // Get this student's attendance records for those sessions
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
            'total_sessions'  => $totalSessions,
            'present'         => $presentCount,
            'absent'          => $absentCount,
            'late'            => $lateCount,
            'excused'         => $excusedCount,
            'percentage'      => $percentage,
            'records'         => $records->sortByDesc(fn ($r) => $r->session->date)->values()->map(fn ($r) => [
                'date'   => $r->session->date->toDateString(),
                'status' => $r->status,
            ]),
        ]);
    }
}
