<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\Enrollment;
use App\Models\Teacher;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    /**
     * GET /teacher/{teacherId}/profile
     */
    public function show(int $teacherId)
    {
        $teacher = Teacher::where('id', $teacherId)
            ->with([
                'user',
                'assignments.section.schoolClass.schoolYear',
                'assignments.subject',
            ])
            ->firstOrFail();

        $assignments = $teacher->assignments;

        $subjectNames = $assignments
            ->map(fn ($a) => optional($a->subject)->name)
            ->filter()->unique()->values();

        $schoolYearNames = $assignments
            ->map(fn ($a) => optional(optional(optional($a->section)->schoolClass)->schoolYear)->name)
            ->filter()->unique()->values();

        $sectionIds = $assignments
            ->map(fn ($a) => optional($a->section)->section_id)
            ->filter()->unique()->values();

        // Fetch students per section: id, name, average score, attendance %
        $studentsBySection = [];
        foreach ($sectionIds as $sectionId) {
            $rows = Enrollment::where('section_id', $sectionId)
                ->where('status', 'active')
                ->with('student.user')
                ->get();

            $studentsBySection[$sectionId] = $rows->map(function ($e) use ($sectionId) {
                $studentId = $e->student_id;
                $name = optional(optional($e->student)->user)->name ?? '';

                $avg = AssessmentResult::where('student_id', $studentId)
                    ->whereNotNull('score')
                    ->avg('score');

                $attRows = DB::table('studentattendance')
                    ->join('attendancesession', 'attendancesession.session_id', '=', 'studentattendance.session_id')
                    ->where('studentattendance.student_id', $studentId)
                    ->where('attendancesession.section_id', $sectionId)
                    ->select('studentattendance.status')
                    ->get();

                $attendancePercent = null;
                if ($attRows->count() > 0) {
                    $present = $attRows->where('status', 'present')->count()
                             + $attRows->where('status', 'late')->count();
                    $attendancePercent = round(($present / $attRows->count()) * 100, 1);
                }

                return [
                    'id'                 => $studentId,
                    'name'               => $name,
                    'average_score'      => $avg !== null ? round((float) $avg, 1) : null,
                    'attendance_percent' => $attendancePercent,
                ];
            })->values()->all();
        }

        return response()->json([
            'id'              => $teacher->id,
            'name'            => $teacher->user->name,
            'email'           => $teacher->user->email,
            'phone'           => $teacher->user->phone,
            'profile_picture' => $teacher->user->profile_picture,
            'date_of_birth'   => $teacher->date_of_birth,
            'gender'          => $teacher->gender,
            'address'         => $teacher->address,
            'hire_date'       => $teacher->hire_date,
            'status'          => $teacher->status,

            // Flattened summary fields the Flutter profile page expects
            'subject'         => $subjectNames->implode(', ') ?: null,
            'qualification'   => null,
            'school_year'     => $schoolYearNames->first(),
            'class_count'     => $sectionIds->count(),

            'assignments'     => $assignments->map(function ($a) use ($studentsBySection) {
                $sectionId = optional($a->section)->section_id;
                return [
                    'id'          => $a->assignment_id,
                    'subject'     => optional($a->subject)->name,
                    'section'     => optional($a->section)->name,
                    'class'       => optional(optional($a->section)->schoolClass)->name,
                    'school_year' => optional(optional(optional($a->section)->schoolClass)->schoolYear)->name,
                    'name'        => optional(optional($a->section)->schoolClass)->name
                                     . (optional($a->section)->name ? ' - ' . $a->section->name : ''),
                    'students'    => $sectionId ? ($studentsBySection[$sectionId] ?? []) : [],
                ];
            }),
        ]);
    }
}
