<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Guardian;

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
            'parent_id'       => $guardian->parent_id,
            'name'            => $guardian->user->name,
            'email'           => $guardian->user->email,
            'phone'           => $guardian->user->phone,
            'profile_picture' => $guardian->user->profile_picture,
            'children'  => $guardian->studentLinks->map(fn ($link) => [
                'student_id'   => $link->student->id,
                'name'         => $link->student->user->name,
                'relationship' => $link->relationship,
                'isprimary'    => $link->isprimary,
                'current_enrollment' => $link->student->activeEnrollment ? [
                    'section' => $link->student->activeEnrollment->section->name,
                    'class'   => $link->student->activeEnrollment->section->schoolClass->name,
                ] : null,
            ]),
        ]);
    }
}
