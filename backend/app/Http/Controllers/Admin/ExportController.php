<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\AttendanceSession;
use App\Models\Student;
use App\Models\StudentAttendance;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExportController extends Controller
{
    // ──────────────────────────────────────────────
    //  MARKS EXPORT
    // ──────────────────────────────────────────────

    /**
     * GET /admin/export/marks/csv
     *
     * Export student marks as CSV.
     * Filters: student_id, section_id, subject_id, assessment_id, from, to
     */
    public function marksCsv(Request $request): StreamedResponse
    {
        $results = $this->getMarksData($request);

        return response()->streamDownload(function () use ($results) {
            $handle = fopen('php://output', 'w');

            fputcsv($handle, [
                'Student ID', 'Student Name', 'Assessment', 'Subject',
                'Section', 'Type', 'Date', 'Score', 'Max Score', 'Percentage', 'Grade',
            ]);

            foreach ($results as $r) {
                $percentage = $r->assessment->maxscore > 0
                    ? round(($r->score / $r->assessment->maxscore) * 100, 1)
                    : null;

                fputcsv($handle, [
                    $r->student_id,
                    $r->student->user->name ?? 'N/A',
                    $r->assessment->title,
                    $r->assessment->subject->name ?? 'N/A',
                    $r->assessment->section->name ?? 'N/A',
                    $r->assessment->assessmenttype,
                    $r->assessment->date?->toDateString(),
                    $r->score,
                    $r->assessment->maxscore,
                    $percentage,
                    $r->grade,
                ]);
            }

            fclose($handle);
        }, 'marks_export_' . now()->format('Y-m-d') . '.csv', [
            'Content-Type' => 'text/csv',
        ]);
    }

    /**
     * GET /admin/export/marks/pdf
     *
     * Export student marks as PDF.
     * Filters: student_id, section_id, subject_id, assessment_id, from, to
     */
    public function marksPdf(Request $request)
    {
        $results = $this->getMarksData($request);

        $rows = $results->map(function ($r) {
            return [
                'student_name'   => $r->student->user->name ?? 'N/A',
                'assessment'     => $r->assessment->title,
                'subject'        => $r->assessment->subject->name ?? 'N/A',
                'section'        => $r->assessment->section->name ?? 'N/A',
                'type'           => $r->assessment->assessmenttype,
                'date'           => $r->assessment->date?->toDateString(),
                'score'          => $r->score,
                'max_score'      => $r->assessment->maxscore,
                'percentage'     => $r->assessment->maxscore > 0
                    ? round(($r->score / $r->assessment->maxscore) * 100, 1)
                    : null,
                'grade'          => $r->grade,
            ];
        });

        $summary = [
            'total_results' => $rows->count(),
            'average_score' => $rows->isNotEmpty() ? round($rows->avg('percentage'), 1) : null,
            'highest'       => $rows->max('percentage'),
            'lowest'        => $rows->min('percentage'),
            'pass_rate'     => $rows->isNotEmpty()
                ? round($rows->where('percentage', '>=', 50)->count() / $rows->count() * 100, 1)
                : null,
        ];

        $pdf = Pdf::loadView('exports.marks', [
            'rows'    => $rows,
            'summary' => $summary,
            'date'    => now()->format('Y-m-d'),
        ])->setPaper('a4', 'landscape');

        return $pdf->download('marks_report_' . now()->format('Y-m-d') . '.pdf');
    }

    // ──────────────────────────────────────────────
    //  ATTENDANCE EXPORT
    // ──────────────────────────────────────────────

    /**
     * GET /admin/export/attendance/csv
     *
     * Export student attendance as CSV.
     * Filters: student_id, section_id, from (required), to (required)
     */
    public function attendanceCsv(Request $request): StreamedResponse
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $records = $this->getAttendanceData($request);

        return response()->streamDownload(function () use ($records) {
            $handle = fopen('php://output', 'w');

            fputcsv($handle, [
                'Student ID', 'Student Name', 'Section', 'Date', 'Status',
            ]);

            foreach ($records as $r) {
                fputcsv($handle, [
                    $r->student_id,
                    $r->student->user->name ?? 'N/A',
                    $r->session->section->name ?? 'N/A',
                    $r->session->date?->toDateString(),
                    $r->status,
                ]);
            }

            fclose($handle);
        }, 'attendance_export_' . now()->format('Y-m-d') . '.csv', [
            'Content-Type' => 'text/csv',
        ]);
    }

    /**
     * GET /admin/export/attendance/pdf
     *
     * Export student attendance as PDF.
     * Filters: student_id, section_id, from (required), to (required)
     */
    public function attendancePdf(Request $request)
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $records = $this->getAttendanceData($request);

        $rows = $records->map(fn ($r) => [
            'student_name' => $r->student->user->name ?? 'N/A',
            'section'      => $r->session->section->name ?? 'N/A',
            'date'         => $r->session->date?->toDateString(),
            'status'       => $r->status,
        ]);

        $total = $rows->count();
        $summary = [
            'total_records'   => $total,
            'present'         => $records->where('status', 'present')->count(),
            'absent'          => $records->where('status', 'absent')->count(),
            'late'            => $records->where('status', 'late')->count(),
            'excused'         => $records->where('status', 'excused')->count(),
            'attendance_rate' => $total > 0
                ? round($records->whereIn('status', ['present', 'late'])->count() / $total * 100, 1)
                : null,
        ];

        $pdf = Pdf::loadView('exports.attendance', [
            'rows'    => $rows,
            'summary' => $summary,
            'from'    => $request->from,
            'to'      => $request->to,
            'date'    => now()->format('Y-m-d'),
        ])->setPaper('a4', 'landscape');

        return $pdf->download('attendance_report_' . now()->format('Y-m-d') . '.pdf');
    }

    // ──────────────────────────────────────────────
    //  PRIVATE HELPERS
    // ──────────────────────────────────────────────

    private function getMarksData(Request $request)
    {
        $query = AssessmentResult::with([
            'student.user',
            'assessment.subject',
            'assessment.section',
        ]);

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('assessment_id')) {
            $query->where('assessment_id', $request->assessment_id);
        }

        if ($request->filled('section_id')) {
            $query->whereHas('assessment', fn ($q) => $q->where('section_id', $request->section_id));
        }

        if ($request->filled('subject_id')) {
            $query->whereHas('assessment', fn ($q) => $q->where('subject_id', $request->subject_id));
        }

        if ($request->filled('from')) {
            $query->whereHas('assessment', fn ($q) => $q->where('date', '>=', $request->from));
        }

        if ($request->filled('to')) {
            $query->whereHas('assessment', fn ($q) => $q->where('date', '<=', $request->to));
        }

        return $query->orderBy('student_id')->get();
    }

    private function getAttendanceData(Request $request)
    {
        $sessionQuery = AttendanceSession::whereBetween('date', [$request->from, $request->to]);

        if ($request->filled('section_id')) {
            $sessionQuery->where('section_id', $request->section_id);
        }

        $sessionIds = $sessionQuery->pluck('session_id');

        $query = StudentAttendance::whereIn('session_id', $sessionIds)
            ->with(['student.user', 'session.section']);

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        return $query->orderBy('student_id')->get();
    }
}
