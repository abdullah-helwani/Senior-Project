<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\AttendanceSession;
use App\Models\Guardian;
use App\Models\Student;
use App\Models\StudentAttendance;
use Illuminate\Http\Request;

class ChildAttendanceController extends Controller
{
    /**
     * GET /parent/{parentId}/children/{studentId}/attendance
     */
    public function index(int $parentId, int $studentId, Request $request)
    {
        $this->authorizeChild($parentId, $studentId);

        $student = Student::with('activeEnrollment')->findOrFail($studentId);

        if (! $student->activeEnrollment) {
            return response()->json(['message' => 'No active enrollment found.'], 404);
        }

        $sectionId = $student->activeEnrollment->section_id;

        $sessionsQuery = AttendanceSession::where('section_id', $sectionId);

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
            'total_sessions' => $totalSessions,
            'present'        => $presentCount,
            'absent'         => $absentCount,
            'late'           => $lateCount,
            'excused'        => $excusedCount,
            'percentage'     => $percentage,
            'records'        => $records->sortByDesc(fn ($r) => $r->session->date)->values()->map(fn ($r) => [
                'date'   => $r->session->date->toDateString(),
                'status' => $r->status,
            ]),
        ]);
    }

    private function authorizeChild(int $parentId, int $studentId): void
    {
        Guardian::where('parent_id', $parentId)
            ->whereHas('studentLinks', fn ($q) => $q->where('student_id', $studentId))
            ->firstOrFail();
    }
}
