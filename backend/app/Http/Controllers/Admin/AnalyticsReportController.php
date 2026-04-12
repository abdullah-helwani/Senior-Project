<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\AnalyticsMetric;
use App\Models\AnalyticsReport;
use App\Models\AssessmentResult;
use App\Models\AttendanceSession;
use App\Models\BehaviorLog;
use App\Models\Enrollment;
use App\Models\StudentAttendance;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsReportController extends Controller
{
    /**
     * GET /admin/analytics/reports
     *
     * List saved reports. Filters: reporttype, from, to
     */
    public function index(Request $request)
    {
        $query = AnalyticsReport::with('generatedByAdmin.user');

        if ($request->filled('reporttype')) {
            $query->where('reporttype', $request->reporttype);
        }

        if ($request->filled('from')) {
            $query->where('periodstart', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('periodend', '<=', $request->to);
        }

        $reports = $query->orderByDesc('generated_at')
            ->paginate($request->input('per_page', 20));

        return response()->json($reports);
    }

    /**
     * GET /admin/analytics/reports/{id}
     *
     * Show a saved report with its metrics.
     */
    public function show(int $id)
    {
        $report = AnalyticsReport::where('report_id', $id)
            ->with(['metrics', 'generatedByAdmin.user'])
            ->firstOrFail();

        return response()->json($report);
    }

    /**
     * POST /admin/analytics/reports
     *
     * Generate and save a new analytics report.
     * Body: reporttype (attendance|academic|behavior), periodstart, periodend
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'reporttype'  => 'required|in:attendance,academic,behavior',
            'periodstart' => 'required|date',
            'periodend'   => 'required|date|after_or_equal:periodstart',
        ]);

        $admin = Admin::where('user_id', auth()->id())->firstOrFail();

        return DB::transaction(function () use ($data, $admin) {
            $report = AnalyticsReport::create([
                'reporttype'          => $data['reporttype'],
                'periodstart'         => $data['periodstart'],
                'periodend'           => $data['periodend'],
                'generated_at'        => now(),
                'generatedbyadmin_id' => $admin->admin_id,
            ]);

            $metrics = match ($data['reporttype']) {
                'attendance' => $this->generateAttendanceMetrics($data['periodstart'], $data['periodend']),
                'academic'   => $this->generateAcademicMetrics($data['periodstart'], $data['periodend']),
                'behavior'   => $this->generateBehaviorMetrics($data['periodstart'], $data['periodend']),
            };

            foreach ($metrics as $metric) {
                AnalyticsMetric::create([
                    'report_id'   => $report->report_id,
                    'metricname'  => $metric['metricname'],
                    'metricvalue' => (string) $metric['metricvalue'],
                    'dimension'   => $metric['dimension'] ?? null,
                ]);
            }

            return response()->json($report->load('metrics'), 201);
        });
    }

    /**
     * DELETE /admin/analytics/reports/{id}
     */
    public function destroy(int $id)
    {
        $report = AnalyticsReport::where('report_id', $id)->firstOrFail();

        AnalyticsMetric::where('report_id', $id)->delete();
        $report->delete();

        return response()->json(['message' => 'Report deleted successfully.']);
    }

    /**
     * GET /admin/analytics/live/attendance
     *
     * Real-time attendance stats without saving a report. Filters: from, to, section_id
     */
    public function liveAttendance(Request $request)
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $sessionQuery = AttendanceSession::whereBetween('date', [$request->from, $request->to]);

        if ($request->filled('section_id')) {
            $sessionQuery->where('section_id', $request->section_id);
        }

        $sessionIds = $sessionQuery->pluck('session_id');
        $records = StudentAttendance::whereIn('session_id', $sessionIds)->get();

        $total = $records->count();
        $present = $records->where('status', 'present')->count();
        $absent = $records->where('status', 'absent')->count();
        $late = $records->where('status', 'late')->count();
        $excused = $records->where('status', 'excused')->count();

        return response()->json([
            'period'     => ['from' => $request->from, 'to' => $request->to],
            'total_records' => $total,
            'present'    => $present,
            'absent'     => $absent,
            'late'       => $late,
            'excused'    => $excused,
            'attendance_rate' => $total > 0
                ? round(($present + $late) / $total * 100, 1)
                : null,
        ]);
    }

    /**
     * GET /admin/analytics/live/academic
     *
     * Real-time academic stats. Filters: from, to, section_id, subject_id
     */
    public function liveAcademic(Request $request)
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $query = AssessmentResult::whereHas('assessment', function ($q) use ($request) {
            $q->whereBetween('date', [$request->from, $request->to]);

            if ($request->filled('section_id')) {
                $q->where('section_id', $request->section_id);
            }

            if ($request->filled('subject_id')) {
                $q->where('subject_id', $request->subject_id);
            }
        });

        $results = $query->get();

        return response()->json([
            'period'        => ['from' => $request->from, 'to' => $request->to],
            'total_results' => $results->count(),
            'average_score' => $results->isNotEmpty() ? round($results->avg('score'), 2) : null,
            'highest_score' => $results->max('score'),
            'lowest_score'  => $results->min('score'),
            'pass_count'    => $results->where('score', '>=', 50)->count(),
            'fail_count'    => $results->where('score', '<', 50)->count(),
            'pass_rate'     => $results->isNotEmpty()
                ? round($results->where('score', '>=', 50)->count() / $results->count() * 100, 1)
                : null,
        ]);
    }

    /**
     * GET /admin/analytics/live/behavior
     *
     * Real-time behavior stats. Filters: from, to, section_id
     */
    public function liveBehavior(Request $request)
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $query = BehaviorLog::whereBetween('date', [$request->from, $request->to]);

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        $logs = $query->get();

        return response()->json([
            'period'   => ['from' => $request->from, 'to' => $request->to],
            'total'    => $logs->count(),
            'positive' => $logs->where('type', 'positive')->count(),
            'negative' => $logs->where('type', 'negative')->count(),
            'neutral'  => $logs->where('type', 'neutral')->count(),
        ]);
    }

    // ── Private helpers to build metrics arrays ──

    private function generateAttendanceMetrics(string $from, string $to): array
    {
        $sessionIds = AttendanceSession::whereBetween('date', [$from, $to])->pluck('session_id');
        $records = StudentAttendance::whereIn('session_id', $sessionIds)->get();
        $total = $records->count();

        return [
            ['metricname' => 'total_records',   'metricvalue' => $total,   'dimension' => 'count'],
            ['metricname' => 'present',          'metricvalue' => $records->where('status', 'present')->count(), 'dimension' => 'count'],
            ['metricname' => 'absent',           'metricvalue' => $records->where('status', 'absent')->count(),  'dimension' => 'count'],
            ['metricname' => 'late',             'metricvalue' => $records->where('status', 'late')->count(),    'dimension' => 'count'],
            ['metricname' => 'excused',          'metricvalue' => $records->where('status', 'excused')->count(), 'dimension' => 'count'],
            ['metricname' => 'attendance_rate',  'metricvalue' => $total > 0
                ? round(($records->whereIn('status', ['present', 'late'])->count() / $total) * 100, 1)
                : 0, 'dimension' => 'percentage'],
        ];
    }

    private function generateAcademicMetrics(string $from, string $to): array
    {
        $results = AssessmentResult::whereHas('assessment', function ($q) use ($from, $to) {
            $q->whereBetween('date', [$from, $to]);
        })->get();

        return [
            ['metricname' => 'total_results',  'metricvalue' => $results->count(),           'dimension' => 'count'],
            ['metricname' => 'average_score',   'metricvalue' => $results->isNotEmpty() ? round($results->avg('score'), 2) : 0, 'dimension' => 'score'],
            ['metricname' => 'highest_score',   'metricvalue' => $results->max('score') ?? 0, 'dimension' => 'score'],
            ['metricname' => 'lowest_score',    'metricvalue' => $results->min('score') ?? 0, 'dimension' => 'score'],
            ['metricname' => 'pass_rate',       'metricvalue' => $results->isNotEmpty()
                ? round($results->where('score', '>=', 50)->count() / $results->count() * 100, 1)
                : 0, 'dimension' => 'percentage'],
        ];
    }

    private function generateBehaviorMetrics(string $from, string $to): array
    {
        $logs = BehaviorLog::whereBetween('date', [$from, $to])->get();

        return [
            ['metricname' => 'total_logs', 'metricvalue' => $logs->count(),                          'dimension' => 'count'],
            ['metricname' => 'positive',   'metricvalue' => $logs->where('type', 'positive')->count(), 'dimension' => 'count'],
            ['metricname' => 'negative',   'metricvalue' => $logs->where('type', 'negative')->count(), 'dimension' => 'count'],
            ['metricname' => 'neutral',    'metricvalue' => $logs->where('type', 'neutral')->count(),  'dimension' => 'count'],
        ];
    }
}
