<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Teacher;

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

        return response()->json([
            'id'            => $teacher->id,
            'name'          => $teacher->user->name,
            'email'         => $teacher->user->email,
            'phone'         => $teacher->user->phone,
            'date_of_birth' => $teacher->date_of_birth,
            'gender'        => $teacher->gender,
            'address'       => $teacher->address,
            'hire_date'     => $teacher->hire_date,
            'status'        => $teacher->status,
            'assignments'   => $teacher->assignments->map(fn ($a) => [
                'subject'     => $a->subject->name,
                'section'     => $a->section->name,
                'class'       => $a->section->schoolClass->name,
                'school_year' => $a->section->schoolClass->schoolYear->name,
            ]),
        ]);
    }
}
