<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Assessment;
use App\Models\AssessmentResult;
use App\Models\Enrollment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AssessmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Assessment::with(['subject', 'section.schoolClass']);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('assessmenttype')) {
            $query->where('assessmenttype', $request->assessmenttype);
        }

        return response()->json($query->latest('date')->paginate($request->input('per_page', 15)));
    }

    public function store(Request $request)
    {
        $request->validate([
            'subject_id'         => 'required|exists:subjects,id',
            'section_id'         => 'required|exists:section,section_id',
            'title'              => 'required|string|max:255',
            'createdbyteacherid' => 'required|exists:teachers,teacher_id',
            'assessmenttype'     => 'required|in:exam,quiz,assignment,project,other',
            'date'               => 'required|date',
            'maxscore'           => 'required|numeric|min:1',
        ]);

        $assessment = Assessment::create($request->only([
            'subject_id', 'section_id', 'title',
            'createdbyteacherid', 'assessmenttype', 'date', 'maxscore',
        ]));

        return response()->json($assessment->load(['subject', 'section.schoolClass']), 201);
    }

    public function show(int $id)
    {
        $assessment = Assessment::with([
            'subject',
            'section.schoolClass.schoolYear',
            'results.student.user',
        ])->findOrFail($id);

        return response()->json($assessment);
    }

    public function storeResults(Request $request, int $id)
    {
        $assessment = Assessment::findOrFail($id);

        $request->validate([
            'results'              => 'required|array|min:1',
            'results.*.student_id' => 'required|exists:students,id',
            'results.*.score'      => "required|numeric|min:0|max:{$assessment->maxscore}",
        ]);

        $enrolledIds = Enrollment::where('section_id', $assessment->section_id)
            ->where('status', 'active')
            ->pluck('student_id')
            ->toArray();

        $invalidStudents = collect($request->results)
            ->pluck('student_id')
            ->diff($enrolledIds);

        if ($invalidStudents->isNotEmpty()) {
            return response()->json([
                'message'          => 'Some students are not enrolled in this section.',
                'invalid_students' => $invalidStudents->values(),
            ], 422);
        }

        $now = now();

        $rows = collect($request->results)->map(function ($item) use ($assessment, $now) {
            return [
                'assessment_id' => $assessment->assessment_id,
                'student_id'    => $item['student_id'],
                'score'         => $item['score'],
                'grade'         => AssessmentResult::calculateGrade($item['score'], $assessment->maxscore),
                'publishedat'   => $now,
            ];
        })->toArray();

        DB::transaction(function () use ($rows) {
            AssessmentResult::upsert(
                $rows,
                ['assessment_id', 'student_id'],
                ['score', 'grade', 'publishedat']
            );
        });

        return response()->json([
            'message' => 'Marks saved successfully.',
            'count'   => count($rows),
        ]);
    }

    public function results(int $id)
    {
        $assessment = Assessment::with(['subject', 'section.schoolClass'])->findOrFail($id);

        $results = AssessmentResult::with('student.user')
            ->where('assessment_id', $id)
            ->get()
            ->map(function ($r) use ($assessment) {
                return [
                    'result_id'    => $r->result_id,
                    'student_id'   => $r->student_id,
                    'student_name' => $r->student->user->name,
                    'score'        => $r->score,
                    'max_score'    => $assessment->maxscore,
                    'percentage'   => round(($r->score / $assessment->maxscore) * 100, 1),
                    'grade'        => $r->grade,
                    'published_at' => $r->publishedat,
                ];
            });

        return response()->json([
            'assessment' => [
                'id'             => $assessment->assessment_id,
                'title'          => $assessment->title,
                'subject'        => $assessment->subject->name,
                'section'        => $assessment->section->name,
                'class'          => $assessment->section->schoolClass->name,
                'assessmenttype' => $assessment->assessmenttype,
                'date'           => $assessment->date,
                'maxscore'       => $assessment->maxscore,
            ],
            'results' => $results,
            'summary' => [
                'total_students' => $results->count(),
                'average_score'  => round($results->avg('score'), 2),
                'highest_score'  => $results->max('score'),
                'lowest_score'   => $results->min('score'),
                'pass_rate'      => $results->count()
                    ? round(($results->where('grade', '!=', 'F')->count() / $results->count()) * 100, 1)
                    : 0,
            ],
        ]);
    }

    public function update(Request $request, int $id)
    {
        $assessment = Assessment::findOrFail($id);

        $request->validate([
            'title'          => 'sometimes|string|max:255',
            'assessmenttype' => 'sometimes|in:exam,quiz,assignment,project,other',
            'date'           => 'sometimes|date',
            'maxscore'       => 'sometimes|numeric|min:1',
        ]);

        $assessment->update($request->only(['title', 'assessmenttype', 'date', 'maxscore']));

        return response()->json($assessment->load(['subject', 'section.schoolClass']));
    }

    public function destroy(int $id)
    {
        Assessment::findOrFail($id)->delete();

        return response()->json(['message' => 'Assessment deleted successfully.']);
    }
}
