<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\AttendanceSession;
use App\Models\BehaviorLog;
use App\Models\Enrollment;
use App\Models\Student;
use App\Models\StudentAttendance;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class ReportCardController extends Controller
{
    /**
     * GET /admin/report-cards/student/{studentId}
     *
     * Generate an end-of-term report card PDF for a single student.
     * Query params: term (required), from (required), to (required)
     */
    public function student(int $studentId, Request $request)
    {
        $request->validate([
            'term' => 'required|string',
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $student = Student::with([
            'user',
            'activeEnrollment.section.schoolClass.schoolYear',
        ])->findOrFail($studentId);

        $data = $this->buildStudentReportData($student, $request->from, $request->to, $request->term);

        $pdf = Pdf::loadView('exports.report-card', [
            'student'  => $data,
            'term'     => $request->term,
            'from'     => $request->from,
            'to'       => $request->to,
            'date'     => now()->format('Y-m-d'),
        ])->setPaper('a4', 'portrait');

        $filename = 'report_card_' . str_replace(' ', '_', $student->user->name) . '_' . now()->format('Y-m-d') . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * GET /admin/report-cards/section/{sectionId}
     *
     * Generate report cards for all students in a section (single PDF, one page per student).
     * Query params: term (required), from (required), to (required)
     */
    public function section(int $sectionId, Request $request)
    {
        $request->validate([
            'term' => 'required|string',
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $enrollments = Enrollment::where('section_id', $sectionId)
            ->where('status', 'active')
            ->with('student.user', 'section.schoolClass.schoolYear')
            ->get();

        if ($enrollments->isEmpty()) {
            return response()->json(['message' => 'No active enrollments found in this section.'], 404);
        }

        $students = [];
        foreach ($enrollments as $enrollment) {
            $students[] = $this->buildStudentReportData(
                $enrollment->student,
                $request->from,
                $request->to,
                $request->term,
                $enrollment
            );
        }

        $sectionName = $enrollments->first()->section->name;
        $className = $enrollments->first()->section->schoolClass->name;

        $pdf = Pdf::loadView('exports.report-cards-bulk', [
            'students'     => $students,
            'section_name' => $sectionName,
            'class_name'   => $className,
            'term'         => $request->term,
            'from'         => $request->from,
            'to'           => $request->to,
            'date'         => now()->format('Y-m-d'),
        ])->setPaper('a4', 'portrait');

        $filename = 'report_cards_' . str_replace(' ', '_', $sectionName) . '_' . now()->format('Y-m-d') . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * GET /admin/report-cards/student/{studentId}/preview
     *
     * Return the report card data as JSON (for frontend preview before printing).
     */
    public function preview(int $studentId, Request $request)
    {
        $request->validate([
            'term' => 'required|string',
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $student = Student::with([
            'user',
            'activeEnrollment.section.schoolClass.schoolYear',
        ])->findOrFail($studentId);

        $data = $this->buildStudentReportData($student, $request->from, $request->to, $request->term);

        return response()->json($data);
    }

    // ──────────────────────────────────────────────
    //  PRIVATE HELPERS
    // ──────────────────────────────────────────────

    private function buildStudentReportData(Student $student, string $from, string $to, string $term, ?Enrollment $enrollment = null): array
    {
        $enrollment = $enrollment ?? $student->activeEnrollment;
        $sectionId = $enrollment?->section_id;

        // ── Grades by subject ──
        $results = AssessmentResult::where('student_id', $student->id)
            ->whereHas('assessment', function ($q) use ($sectionId, $from, $to) {
                $q->where('section_id', $sectionId)
                  ->whereBetween('date', [$from, $to]);
            })
            ->with('assessment.subject')
            ->get();

        $subjectGrades = $results->groupBy(fn ($r) => $r->assessment->subject->name)
            ->map(function ($subjectResults, $subjectName) {
                $assessments = $subjectResults->map(fn ($r) => [
                    'title'      => $r->assessment->title,
                    'type'       => $r->assessment->assessmenttype,
                    'score'      => $r->score,
                    'max_score'  => $r->assessment->maxscore,
                    'percentage' => $r->assessment->maxscore > 0
                        ? round(($r->score / $r->assessment->maxscore) * 100, 1)
                        : 0,
                ]);

                $avgPercentage = round($assessments->avg('percentage'), 1);

                return [
                    'subject'           => $subjectName,
                    'assessments'       => $assessments->values(),
                    'average'           => $avgPercentage,
                    'total_assessments' => $assessments->count(),
                ];
            })->values();

        // ── Overall GPA ──
        $overallAvg = $subjectGrades->isNotEmpty()
            ? round($subjectGrades->avg('average'), 1)
            : null;

        // ── Attendance ──
        $sessionIds = AttendanceSession::where('section_id', $sectionId)
            ->whereBetween('date', [$from, $to])
            ->pluck('session_id');

        $attendanceRecords = StudentAttendance::whereIn('session_id', $sessionIds)
            ->where('student_id', $student->id)
            ->get();

        $totalSessions = $sessionIds->count();
        $presentCount = $attendanceRecords->whereIn('status', ['present', 'late'])->count();

        $attendance = [
            'total_days' => $totalSessions,
            'present'    => $attendanceRecords->where('status', 'present')->count(),
            'absent'     => $attendanceRecords->where('status', 'absent')->count(),
            'late'       => $attendanceRecords->where('status', 'late')->count(),
            'excused'    => $attendanceRecords->where('status', 'excused')->count(),
            'rate'       => $totalSessions > 0 ? round(($presentCount / $totalSessions) * 100, 1) : null,
        ];

        // ── Behavior ──
        $behaviorLogs = BehaviorLog::where('student_id', $student->id)
            ->where('section_id', $sectionId)
            ->whereBetween('date', [$from, $to])
            ->get();

        $behavior = [
            'positive' => $behaviorLogs->where('type', 'positive')->count(),
            'negative' => $behaviorLogs->where('type', 'negative')->count(),
            'neutral'  => $behaviorLogs->where('type', 'neutral')->count(),
            'notes'    => $behaviorLogs->map(fn ($l) => [
                'type'  => $l->type,
                'title' => $l->title,
                'date'  => $l->date->toDateString(),
            ])->values(),
        ];

        return [
            'student_id'   => $student->id,
            'name'         => $student->user->name,
            'email'        => $student->user->email,
            'section'      => $enrollment?->section->name,
            'class'        => $enrollment?->section->schoolClass->name,
            'school_year'  => $enrollment?->section->schoolClass->schoolYear->name ?? null,
            'term'         => $term,
            'subjects'     => $subjectGrades,
            'overall_average' => $overallAvg,
            'attendance'   => $attendance,
            'behavior'     => $behavior,
        ];
    }
}
