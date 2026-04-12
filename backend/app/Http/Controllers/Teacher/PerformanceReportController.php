<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\AttendanceSession;
use App\Models\BehaviorLog;
use App\Models\Enrollment;
use App\Models\StudentAttendance;
use App\Models\Teacher;
use Carbon\Carbon;
use Illuminate\Http\Request;

class PerformanceReportController extends Controller
{
    /**
     * GET /teacher/{teacherId}/performance-report
     *
     * Weekly student performance report for a section.
     * Combines: assessment scores, attendance, and behavior logs.
     *
     * Query params:
     *   section_id (required)
     *   subject_id (optional — filter assessments by subject)
     *   week_of    (optional — date within the week, defaults to current week)
     */
    public function index(int $teacherId, Request $request)
    {
        Teacher::findOrFail($teacherId);

        $request->validate([
            'section_id' => 'required|integer',
        ]);

        $sectionId = $request->section_id;
        $weekOf = $request->input('week_of', now()->toDateString());
        $weekStart = Carbon::parse($weekOf)->startOfWeek(Carbon::SUNDAY);
        $weekEnd = $weekStart->copy()->addDays(4); // Sunday through Thursday

        // Get enrolled students
        $enrollments = Enrollment::where('section_id', $sectionId)
            ->where('status', 'active')
            ->with('student.user')
            ->get();

        $studentIds = $enrollments->pluck('student_id');

        // --- Attendance for the week ---
        $sessionIds = AttendanceSession::where('section_id', $sectionId)
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->pluck('session_id');

        $totalSessions = $sessionIds->count();

        $attendanceRecords = StudentAttendance::whereIn('session_id', $sessionIds)
            ->whereIn('student_id', $studentIds)
            ->get()
            ->groupBy('student_id');

        // --- Assessment results published this week ---
        $resultsQuery = AssessmentResult::whereIn('student_id', $studentIds)
            ->whereBetween('publishedat', [$weekStart, $weekEnd])
            ->with('assessment.subject');

        if ($request->filled('subject_id')) {
            $resultsQuery->whereHas('assessment', fn ($q) => $q->where('subject_id', $request->subject_id));
        }

        $assessmentResults = $resultsQuery->get()->groupBy('student_id');

        // --- Behavior logs for the week ---
        $behaviorLogs = BehaviorLog::where('section_id', $sectionId)
            ->whereIn('student_id', $studentIds)
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->get()
            ->groupBy('student_id');

        // --- Build per-student report ---
        $report = $enrollments->map(function ($enrollment) use (
            $attendanceRecords, $assessmentResults, $behaviorLogs, $totalSessions
        ) {
            $sid = $enrollment->student_id;

            // Attendance
            $att = $attendanceRecords->get($sid, collect());
            $presentCount = $att->whereIn('status', ['present', 'late'])->count();
            $attPercentage = $totalSessions > 0
                ? round(($presentCount / $totalSessions) * 100, 1)
                : null;

            // Assessments
            $results = $assessmentResults->get($sid, collect());
            $assessments = $results->map(fn ($r) => [
                'title'      => $r->assessment->title,
                'subject'    => $r->assessment->subject->name,
                'score'      => $r->score,
                'max_score'  => $r->assessment->maxscore,
                'percentage' => round(($r->score / $r->assessment->maxscore) * 100, 1),
                'grade'      => $r->grade,
            ]);

            $avgScore = $assessments->isNotEmpty()
                ? round($assessments->avg('percentage'), 1)
                : null;

            // Behavior
            $logs = $behaviorLogs->get($sid, collect());

            return [
                'student_id'   => $sid,
                'name'         => $enrollment->student->user->name,
                'attendance'   => [
                    'days_present'  => $presentCount,
                    'total_days'    => $totalSessions,
                    'percentage'    => $attPercentage,
                    'statuses'      => $att->pluck('status')->values(),
                ],
                'assessments'  => [
                    'results'       => $assessments->values(),
                    'average_score' => $avgScore,
                ],
                'behavior'     => [
                    'positive' => $logs->where('type', 'positive')->count(),
                    'negative' => $logs->where('type', 'negative')->count(),
                    'neutral'  => $logs->where('type', 'neutral')->count(),
                    'entries'  => $logs->map(fn ($l) => [
                        'type'  => $l->type,
                        'title' => $l->title,
                        'date'  => $l->date->toDateString(),
                    ])->values(),
                ],
            ];
        });

        return response()->json([
            'section_id' => (int) $sectionId,
            'week_start' => $weekStart->toDateString(),
            'week_end'   => $weekEnd->toDateString(),
            'total_sessions' => $totalSessions,
            'students'   => $report->values(),
        ]);
    }
}
