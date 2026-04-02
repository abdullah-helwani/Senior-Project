<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Homework;
use App\Models\Teacher;
use Illuminate\Http\Request;

class HomeworkController extends Controller
{
    /**
     * List all homework assigned by this teacher.
     *
     * Query params:
     *   subject_id - filter by subject
     *   section_id - filter by section
     */
    public function index(int $teacherId, Request $request)
    {
        Teacher::findOrFail($teacherId);

        $query = Homework::with(['subject', 'section.schoolClass'])
            ->where('teacher_id', $teacherId);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        return response()->json(
            $query->latest('due_date')->paginate($request->input('per_page', 15))
        );
    }

    /**
     * Show a single homework with section/subject details.
     */
    public function show(int $teacherId, int $homeworkId)
    {
        $homework = Homework::with(['subject', 'section.schoolClass.schoolYear', 'teacher.user'])
            ->where('teacher_id', $teacherId)
            ->findOrFail($homeworkId);

        return response()->json($homework);
    }

    /**
     * Create (assign) new homework to a section.
     */
    public function store(int $teacherId, Request $request)
    {
        Teacher::findOrFail($teacherId);

        $request->validate([
            'subject_id'  => 'required|exists:subjects,id',
            'section_id'  => 'required|exists:sections,id',
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'due_date'    => 'required|date|after:today',
        ]);

        $homework = Homework::create([
            'teacher_id'  => $teacherId,
            'subject_id'  => $request->subject_id,
            'section_id'  => $request->section_id,
            'title'       => $request->title,
            'description' => $request->description,
            'due_date'    => $request->due_date,
        ]);

        return response()->json($homework->load(['subject', 'section.schoolClass']), 201);
    }

    /**
     * Update a homework assignment.
     */
    public function update(int $teacherId, int $homeworkId, Request $request)
    {
        $homework = Homework::where('teacher_id', $teacherId)->findOrFail($homeworkId);

        $request->validate([
            'title'       => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'due_date'    => 'sometimes|date',
        ]);

        $homework->update($request->only(['title', 'description', 'due_date']));

        return response()->json($homework->load(['subject', 'section.schoolClass']));
    }

    /**
     * Delete a homework assignment.
     */
    public function destroy(int $teacherId, int $homeworkId)
    {
        Homework::where('teacher_id', $teacherId)->findOrFail($homeworkId)->delete();

        return response()->json(['message' => 'Homework deleted successfully.']);
    }
}
