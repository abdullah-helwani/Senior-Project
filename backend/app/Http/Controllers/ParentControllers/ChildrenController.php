<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\Enrollment;
use App\Models\Guardian;
use Illuminate\Support\Facades\DB;

class ChildrenController extends Controller
{
    /**
     * GET /parent/{parentId}/children
     *
     * Returns all children linked to this parent with their profile + enrollment info.
     */
    public function index(int $parentId)
    {
        $guardian = Guardian::where('parent_id', $parentId)
            ->firstOrFail();

        $children = $guardian->studentLinks()
            ->with(['student.user', 'student.activeEnrollment.section.schoolClass.schoolYear'])
            ->get()
            ->map(function ($link) {
                $student = $link->student;

                return [
                    'student_id'    => $student->id,
                    'name'          => $student->user->name,
                    'email'         => $student->user->email,
                    'date_of_birth' => $student->date_of_birth,
                    'gender'        => $student->gender,
                    'status'        => $student->status,
                    'relationship'  => $link->relationship,
                    'isprimary'     => $link->isprimary,
                    'average_score'          => $this->avgScore($student->id),
                    'attendance_percent'     => $this->attendancePercent($student->id),
                    'pending_homework_count' => $this->pendingHomework($student->id),
                    'current_enrollment' => $student->activeEnrollment ? [
                        'section'     => $student->activeEnrollment->section->name,
                        'class'       => $student->activeEnrollment->section->schoolClass->name,
                        'school_year' => $student->activeEnrollment->section->schoolClass->schoolYear->name,
                    ] : null,
                ];
            });

        return response()->json([
            'total_children' => $children->count(),
            'children'       => $children,
        ]);
    }

    private function avgScore(int $studentId): float
    {
        $results = AssessmentResult::where('student_id', $studentId)
            ->whereNotNull('publishedat')
            ->with('assessment')
            ->get();

        if ($results->isEmpty()) return 0.0;

        $bySubject = $results->groupBy(fn ($r) => $r->assessment->subject_id)
            ->map(function ($group) {
                $pcts = $group->map(fn ($r) => $r->assessment->maxscore > 0
                    ? ($r->score / $r->assessment->maxscore) * 100
                    : 0);
                return $pcts->avg();
            });

        return round($bySubject->avg() ?? 0, 1);
    }

    private function attendancePercent(int $studentId): float
    {
        $total   = DB::table('studentattendance')->where('student_id', $studentId)->count();
        $present = DB::table('studentattendance')->where('student_id', $studentId)->where('status', 'present')->count();
        return $total > 0 ? round($present / $total * 100, 1) : 0.0;
    }

    private function pendingHomework(int $studentId): int
    {
        $enrollment = Enrollment::where('student_id', $studentId)->where('status', 'active')->first();
        if (! $enrollment) return 0;

        $assigned  = DB::table('homework')
            ->where('section_id', $enrollment->section_id)
            ->where('due_date', '>=', now()->toDateString())
            ->pluck('id');

        $submitted = DB::table('homeworksubmission')
            ->where('student_id', $studentId)
            ->whereIn('homework_id', $assigned)
            ->pluck('homework_id');

        return $assigned->diff($submitted)->count();
    }
}
