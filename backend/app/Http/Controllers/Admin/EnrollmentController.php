<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use Illuminate\Http\Request;

class EnrollmentController extends Controller
{
    /**
     * List enrollments, optionally filtered by section or student.
     */
    public function index(Request $request)
    {
        $query = Enrollment::with(['student.user', 'section.schoolClass.schoolYear']);

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        return response()->json($query->get());
    }

    /**
     * Enroll a student into a section.
     */
    public function store(Request $request)
    {
        $request->validate([
            'student_id' => 'required|exists:students,id',
            'section_id' => 'required|exists:section,section_id',
            'status'     => 'nullable|in:active,completed,dropped',
        ]);

        // Prevent duplicate active enrollment in the same section
        $exists = Enrollment::where('student_id', $request->student_id)
            ->where('section_id', $request->section_id)
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'Student is already enrolled in this section.',
            ], 422);
        }

        $enrollment = Enrollment::create([
            'student_id' => $request->student_id,
            'section_id' => $request->section_id,
            'status'     => $request->status ?? 'active',
        ]);

        return response()->json($enrollment->load(['student.user', 'section.schoolClass']), 201);
    }

    /**
     * Update enrollment status (e.g. mark as completed or dropped).
     */
    public function update(Request $request, int $id)
    {
        $enrollment = Enrollment::findOrFail($id);

        $request->validate([
            'status' => 'required|in:active,completed,dropped',
        ]);

        $enrollment->update(['status' => $request->status]);

        return response()->json($enrollment->load(['student.user', 'section.schoolClass']));
    }

    /**
     * Remove an enrollment.
     */
    public function destroy(int $id)
    {
        Enrollment::findOrFail($id)->delete();

        return response()->json(['message' => 'Enrollment removed successfully.']);
    }
}
