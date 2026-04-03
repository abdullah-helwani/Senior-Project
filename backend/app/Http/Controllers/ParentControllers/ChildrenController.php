<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Guardian;

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
}
