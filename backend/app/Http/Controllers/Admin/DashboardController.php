<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AttendanceSession;
use App\Models\BehaviorLog;
use App\Models\Complaint;
use App\Models\Enrollment;
use App\Models\StudentAttendance;
use App\Models\User;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * GET /admin/dashboard
     *
     * Returns all key stats to power the admin home screen.
     */
    public function index()
    {
        $today = Carbon::today();
        $thisWeekStart = Carbon::now()->startOfWeek(Carbon::SUNDAY);
        $thisMonthStart = Carbon::now()->startOfMonth();

        // ── User counts ──
        $totalStudents = User::where('role_type', 'student')->count();
        $totalTeachers = User::where('role_type', 'teacher')->count();
        $totalParents  = User::where('role_type', 'parent')->count();

        $activeStudents  = User::where('role_type', 'student')->where('is_active', true)->count();
        $activeTeachers  = User::where('role_type', 'teacher')->where('is_active', true)->count();

        // ── Enrollments ──
        $activeEnrollments = Enrollment::where('status', 'active')->count();

        // ── Today's attendance ──
        $todaySessions = AttendanceSession::where('date', $today)->pluck('session_id');
        $todayRecords = StudentAttendance::whereIn('session_id', $todaySessions)->get();
        $todayTotal = $todayRecords->count();
        $todayPresent = $todayRecords->whereIn('status', ['present', 'late'])->count();
        $todayAttendancePercentage = $todayTotal > 0
            ? round(($todayPresent / $todayTotal) * 100, 1)
            : null;

        // ── Complaints ──
        $openComplaints    = Complaint::where('status', 'open')->count();
        $pendingComplaints = Complaint::where('status', 'in_review')->count();
        $complaintsThisMonth = Complaint::where('created_at', '>=', $thisMonthStart)->count();

        // ── Behavior logs this week ──
        $behaviorThisWeek = BehaviorLog::where('date', '>=', $thisWeekStart)->get();
        $negativeBehavior = $behaviorThisWeek->where('type', 'negative')->count();
        $positiveBehavior = $behaviorThisWeek->where('type', 'positive')->count();

        // ── Recent activity (last 5 complaints) ──
        $recentComplaints = Complaint::with(['guardian.user', 'student.user'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(fn ($c) => [
                'complaint_id' => $c->complaint_id,
                'subject'      => $c->subject,
                'status'       => $c->status,
                'parent'       => $c->guardian->user->name ?? null,
                'student'      => $c->student->user->name ?? null,
                'created_at'   => $c->created_at,
            ]);

        return response()->json([
            'users' => [
                'total_students'  => $totalStudents,
                'active_students' => $activeStudents,
                'total_teachers'  => $totalTeachers,
                'active_teachers' => $activeTeachers,
                'total_parents'   => $totalParents,
            ],
            'enrollments' => [
                'active' => $activeEnrollments,
            ],
            'today_attendance' => [
                'total_records' => $todayTotal,
                'present'       => $todayPresent,
                'absent'        => $todayRecords->where('status', 'absent')->count(),
                'late'          => $todayRecords->where('status', 'late')->count(),
                'excused'       => $todayRecords->where('status', 'excused')->count(),
                'percentage'    => $todayAttendancePercentage,
            ],
            'complaints' => [
                'open'       => $openComplaints,
                'in_review'  => $pendingComplaints,
                'this_month' => $complaintsThisMonth,
            ],
            'behavior_this_week' => [
                'positive' => $positiveBehavior,
                'negative' => $negativeBehavior,
                'total'    => $behaviorThisWeek->count(),
            ],
            'recent_complaints' => $recentComplaints,
        ]);
    }
}
