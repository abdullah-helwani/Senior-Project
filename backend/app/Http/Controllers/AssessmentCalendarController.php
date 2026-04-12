<?php

namespace App\Http\Controllers;

use App\Models\Assessment;
use App\Models\Enrollment;
use App\Models\TeacherAssignment;
use Illuminate\Http\Request;

class AssessmentCalendarController extends Controller
{
    /**
     * GET /admin/assessment-calendar
     *
     * All upcoming & past assessments. Filters: section_id, subject_id, type, from, to, month
     */
    public function adminCalendar(Request $request)
    {
        $query = Assessment::with(['subject', 'section.schoolClass']);

        $this->applyFilters($query, $request);

        $assessments = $query->orderBy('date')->get();

        return response()->json([
            'assessments' => $this->formatAssessments($assessments),
            'total'       => $assessments->count(),
        ]);
    }

    /**
     * GET /teacher/{teacherId}/assessment-calendar
     *
     * Assessments for sections this teacher is assigned to.
     */
    public function teacherCalendar(int $teacherId, Request $request)
    {
        $sectionIds = TeacherAssignment::where('teacher_id', $teacherId)
            ->pluck('section_id')
            ->unique();

        $query = Assessment::with(['subject', 'section.schoolClass'])
            ->whereIn('section_id', $sectionIds);

        $this->applyFilters($query, $request);

        $assessments = $query->orderBy('date')->get();

        return response()->json([
            'assessments' => $this->formatAssessments($assessments),
            'total'       => $assessments->count(),
        ]);
    }

    /**
     * GET /student/{studentId}/assessment-calendar
     *
     * Assessments for the student's enrolled section.
     */
    public function studentCalendar(int $studentId, Request $request)
    {
        $sectionId = Enrollment::where('student_id', $studentId)
            ->where('status', 'active')
            ->value('section_id');

        if (!$sectionId) {
            return response()->json(['assessments' => [], 'total' => 0]);
        }

        $query = Assessment::with(['subject', 'section.schoolClass'])
            ->where('section_id', $sectionId);

        $this->applyFilters($query, $request);

        $assessments = $query->orderBy('date')->get();

        return response()->json([
            'assessments' => $this->formatAssessments($assessments),
            'total'       => $assessments->count(),
        ]);
    }

    /**
     * GET /parent/{parentId}/children/{studentId}/assessment-calendar
     *
     * Same as student calendar, scoped to a parent's child.
     */
    public function parentCalendar(int $parentId, int $studentId, Request $request)
    {
        return $this->studentCalendar($studentId, $request);
    }

    // ─────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────

    private function applyFilters($query, Request $request): void
    {
        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('type')) {
            $query->where('assessmenttype', $request->type);
        }

        if ($request->filled('month')) {
            // Format: YYYY-MM
            $query->whereRaw("to_char(date, 'YYYY-MM') = ?", [$request->month]);
        }

        if ($request->filled('from')) {
            $query->where('date', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('date', '<=', $request->to);
        }

        // Default: if no date filters, show upcoming (today onward)
        if (!$request->filled('from') && !$request->filled('to') && !$request->filled('month')) {
            $query->where('date', '>=', now()->toDateString());
        }
    }

    private function formatAssessments($assessments): array
    {
        return $assessments->map(fn ($a) => [
            'id'        => $a->assessment_id,
            'title'     => $a->title,
            'type'      => $a->assessmenttype,
            'date'      => $a->date->toDateString(),
            'maxscore'  => $a->maxscore,
            'subject'   => $a->subject->name ?? null,
            'section'   => $a->section->name ?? null,
            'class'     => $a->section->schoolClass->name ?? null,
        ])->toArray();
    }
}
