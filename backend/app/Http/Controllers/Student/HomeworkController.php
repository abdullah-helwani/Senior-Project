<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use App\Models\Homework;
use App\Models\Student;
use Illuminate\Http\Request;

class HomeworkController extends Controller
{
    /**
     * Get all homework assigned to a student across all their active sections.
     *
     * Query params:
     *   subject_id - filter by subject
     *   section_id - filter by section
     *   status     - upcoming | overdue  (based on due_date vs today)
     */
    public function index(int $studentId, Request $request)
    {
        Student::findOrFail($studentId);

        // Get all sections this student is actively enrolled in
        $sectionIds = Enrollment::where('student_id', $studentId)
            ->where('status', 'active')
            ->pluck('section_id');

        $query = Homework::with(['subject', 'section.schoolClass', 'teacher.user'])
            ->whereIn('section_id', $sectionIds);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->input('status') === 'upcoming') {
            $query->where('due_date', '>=', now()->toDateString());
        } elseif ($request->input('status') === 'overdue') {
            $query->where('due_date', '<', now()->toDateString());
        }

        $homework = $query->orderBy('due_date')->paginate($request->input('per_page', 15));

        return response()->json($homework);
    }

    /**
     * Show a single homework detail.
     */
    public function show(int $studentId, int $homeworkId)
    {
        Student::findOrFail($studentId);

        $sectionIds = Enrollment::where('student_id', $studentId)
            ->where('status', 'active')
            ->pluck('section_id');

        $homework = Homework::with(['subject', 'section.schoolClass.schoolYear', 'teacher.user'])
            ->whereIn('section_id', $sectionIds)
            ->findOrFail($homeworkId);

        return response()->json($homework);
    }
}
