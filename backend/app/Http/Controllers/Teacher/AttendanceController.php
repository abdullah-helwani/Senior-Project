<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\AttendanceSession;
use App\Models\Enrollment;
use App\Models\StudentAttendance;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    /**
     * POST /teacher/{teacherId}/attendance
     *
     * Record attendance for a section on a given date.
     * Body:
     * {
     *   "section_id": 1,
     *   "date": "2026-04-03",
     *   "records": [
     *     { "student_id": 7, "status": "present" },
     *     { "student_id": 8, "status": "absent" }
     *   ]
     * }
     */
    public function store(int $teacherId, Request $request)
    {
        $teacher = Teacher::findOrFail($teacherId);

        $request->validate([
            'section_id'          => 'required|integer',
            'date'                => 'required|date',
            'records'             => 'required|array|min:1',
            'records.*.student_id' => 'required|integer',
            'records.*.status'    => 'required|in:present,absent,late,excused',
        ]);

        return DB::transaction(function () use ($request, $teacher) {
            // Create or find the attendance session for this section+date
            $session = AttendanceSession::firstOrCreate([
                'section_id' => $request->section_id,
                'date'       => $request->date,
            ]);

            $inserted = 0;
            $updated = 0;

            foreach ($request->records as $record) {
                $existing = StudentAttendance::where('session_id', $session->session_id)
                    ->where('student_id', $record['student_id'])
                    ->first();

                if ($existing) {
                    $existing->update([
                        'status'          => $record['status'],
                        'capturedbyuserid' => $teacher->user_id,
                    ]);
                    $updated++;
                } else {
                    StudentAttendance::create([
                        'session_id'       => $session->session_id,
                        'student_id'       => $record['student_id'],
                        'status'           => $record['status'],
                        'capturedbyuserid' => $teacher->user_id,
                    ]);
                    $inserted++;
                }
            }

            return response()->json([
                'message'    => 'Attendance recorded successfully.',
                'session_id' => $session->session_id,
                'date'       => $session->date,
                'inserted'   => $inserted,
                'updated'    => $updated,
            ], 201);
        });
    }

    /**
     * GET /teacher/{teacherId}/attendance
     *
     * View attendance for a section on a given date.
     * Query params: section_id (required), date (optional, defaults to today)
     */
    public function index(int $teacherId, Request $request)
    {
        $request->validate([
            'section_id' => 'required|integer',
        ]);

        $date = $request->input('date', now()->toDateString());

        $session = AttendanceSession::where('section_id', $request->section_id)
            ->where('date', $date)
            ->first();

        if (! $session) {
            // Return all enrolled students as "not recorded"
            $enrolled = Enrollment::where('section_id', $request->section_id)
                ->where('status', 'active')
                ->with('student.user')
                ->get();

            return response()->json([
                'date'       => $date,
                'section_id' => (int) $request->section_id,
                'recorded'   => false,
                'students'   => $enrolled->map(fn ($e) => [
                    'student_id' => $e->student_id,
                    'name'       => $e->student->user->name,
                    'status'     => null,
                ]),
            ]);
        }

        $records = StudentAttendance::where('session_id', $session->session_id)
            ->with('student.user')
            ->get();

        $summary = [
            'present' => $records->where('status', 'present')->count(),
            'absent'  => $records->where('status', 'absent')->count(),
            'late'    => $records->where('status', 'late')->count(),
            'excused' => $records->where('status', 'excused')->count(),
        ];

        return response()->json([
            'date'       => $date,
            'section_id' => (int) $request->section_id,
            'session_id' => $session->session_id,
            'recorded'   => true,
            'summary'    => $summary,
            'students'   => $records->map(fn ($r) => [
                'student_id' => $r->student_id,
                'name'       => $r->student->user->name,
                'status'     => $r->status,
            ]),
        ]);
    }
}
