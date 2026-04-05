<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TeacherAssignment;
use Illuminate\Http\Request;

class TeacherAssignmentController extends Controller
{
    /**
     * GET /admin/teacher-assignments
     *
     * List all assignments. Filters: teacher_id, section_id, subject_id
     */
    public function index(Request $request)
    {
        $query = TeacherAssignment::with(['teacher.user', 'section.schoolClass', 'subject']);

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        $assignments = $query->paginate($request->input('per_page', 20));

        return response()->json($assignments);
    }

    /**
     * POST /admin/teacher-assignments
     *
     * Assign a teacher to a section/subject.
     */
    public function store(Request $request)
    {
        $request->validate([
            'teacher_id' => 'required|exists:teachers,id',
            'section_id' => 'required|integer',
            'subject_id' => 'required|exists:subjects,id',
        ]);

        // Prevent duplicate assignment
        $exists = TeacherAssignment::where('teacher_id', $request->teacher_id)
            ->where('section_id', $request->section_id)
            ->where('subject_id', $request->subject_id)
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'This teacher is already assigned to this subject in this section.'], 422);
        }

        $assignment = TeacherAssignment::create($request->only(['teacher_id', 'section_id', 'subject_id']));

        return response()->json(
            $assignment->load(['teacher.user', 'section.schoolClass', 'subject']),
            201
        );
    }

    /**
     * GET /admin/teacher-assignments/{id}
     */
    public function show(int $id)
    {
        $assignment = TeacherAssignment::where('assignment_id', $id)
            ->with(['teacher.user', 'section.schoolClass', 'subject'])
            ->firstOrFail();

        return response()->json($assignment);
    }

    /**
     * PUT /admin/teacher-assignments/{id}
     *
     * Update an assignment (reassign teacher, section, or subject).
     */
    public function update(int $id, Request $request)
    {
        $assignment = TeacherAssignment::where('assignment_id', $id)->firstOrFail();

        $request->validate([
            'teacher_id' => 'sometimes|exists:teachers,id',
            'section_id' => 'sometimes|integer',
            'subject_id' => 'sometimes|exists:subjects,id',
        ]);

        $assignment->update($request->only(['teacher_id', 'section_id', 'subject_id']));

        return response()->json(
            $assignment->load(['teacher.user', 'section.schoolClass', 'subject'])
        );
    }

    /**
     * DELETE /admin/teacher-assignments/{id}
     */
    public function destroy(int $id)
    {
        TeacherAssignment::where('assignment_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Teacher assignment removed successfully.']);
    }
}
