<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Student;

class ProfileController extends Controller
{
    /**
     * GET /student/{studentId}/profile
     *
     * Returns the student's full profile with enrollment info.
     */
    public function show(int $studentId)
    {
        $student = Student::where('id', $studentId)
            ->with([
                'user',
                'activeEnrollment.section.schoolClass.schoolYear',
            ])
            ->firstOrFail();

        return response()->json([
            'id'              => $student->id,
            'name'            => $student->user->name,
            'email'           => $student->user->email,
            'phone'           => $student->user->phone,
            'date_of_birth'   => $student->date_of_birth,
            'gender'          => $student->gender,
            'address'         => $student->address,
            'enrollment_date' => $student->enrollment_date,
            'graduation_year' => $student->graduation_year,
            'status'          => $student->status,
            'current_enrollment' => $student->activeEnrollment ? [
                'section'     => $student->activeEnrollment->section->name,
                'class'       => $student->activeEnrollment->section->schoolClass->name,
                'school_year' => $student->activeEnrollment->section->schoolClass->schoolYear->name,
            ] : null,
        ]);
    }
}
