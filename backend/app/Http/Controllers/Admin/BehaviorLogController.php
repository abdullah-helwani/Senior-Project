<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BehaviorLog;
use Illuminate\Http\Request;

class BehaviorLogController extends Controller
{
    /**
     * GET /admin/behavior-logs
     *
     * List all behavior logs across all teachers.
     * Filters: teacher_id, student_id, section_id, type, from, to
     */
    public function index(Request $request)
    {
        $query = BehaviorLog::with(['student', 'teacher', 'section']);

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('from')) {
            $query->where('date', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('date', '<=', $request->to);
        }

        $logs = $query->orderByDesc('date')
            ->paginate($request->input('per_page', 20));

        return response()->json($logs);
    }

    /**
     * GET /admin/behavior-logs/{id}
     */
    public function show(int $id)
    {
        $log = BehaviorLog::where('log_id', $id)
            ->with(['student', 'teacher', 'section'])
            ->firstOrFail();

        return response()->json($log);
    }

    /**
     * DELETE /admin/behavior-logs/{id}
     */
    public function destroy(int $id)
    {
        BehaviorLog::where('log_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Behavior log deleted successfully.']);
    }
}
