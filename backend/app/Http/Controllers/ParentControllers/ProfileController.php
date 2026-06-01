<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\AssessmentResult;
use App\Models\Enrollment;
use App\Models\Guardian;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    /**
     * GET /parent/{parentId}/profile
     */
    public function show(int $parentId)
    {
        $guardian = Guardian::where('parent_id', $parentId)
            ->with(['user', 'studentLinks.student.user', 'studentLinks.student.activeEnrollment.section.schoolClass'])
            ->firstOrFail();

        return response()->json([
            'id'              => $guardian->parent_id,
            'name'            => $guardian->user->name,
            'email'           => $guardian->user->email,
            'phone'           => $guardian->user->phone,
            'profile_picture' => $guardian->user->profile_picture,
            'children'  => $guardian->studentLinks->map(fn ($link) => [
                'id'           => $link->student->id,
                'name'         => $link->student->user->name,
                'relationship' => $link->relationship,
                'isprimary'    => $link->isprimary,
                'class_name'   => $link->student->activeEnrollment?->section?->schoolClass?->name ?? '',
                'section'      => $link->student->activeEnrollment?->section?->name ?? '',
                'average_score'          => $this->avgScore($link->student->id),
                'attendance_percent'     => $this->attendancePercent($link->student->id),
                'pending_homework_count' => $this->pendingHomework($link->student->id),
                'current_enrollment' => $link->student->activeEnrollment ? [
                    'section' => $link->student->activeEnrollment->section->name,
                    'class'   => $link->student->activeEnrollment->section->schoolClass->name,
                ] : null,
            ]),
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
