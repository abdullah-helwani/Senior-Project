<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Guardian;
use Illuminate\Http\Request;

class ComplaintController extends Controller
{
    /**
     * GET /parent/{parentId}/complaints
     *
     * List all complaints submitted by this parent.
     */
    public function index(int $parentId, Request $request)
    {
        $query = Complaint::where('parent_id', $parentId)
            ->with('student.user');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $complaints = $query->orderByDesc('created_at')
            ->paginate($request->input('per_page', 20));

        return response()->json($complaints);
    }

    /**
     * POST /parent/{parentId}/complaints
     *
     * Submit a new complaint.
     */
    public function store(int $parentId, Request $request)
    {
        $guardian = Guardian::where('parent_id', $parentId)->firstOrFail();

        $request->validate([
            'student_id' => 'nullable|integer',
            'subject'    => 'required|string|max:255',
            'body'       => 'required|string',
        ]);

        // If student_id provided, verify the parent is linked to that child
        if ($request->filled('student_id')) {
            $guardian->studentLinks()
                ->where('student_id', $request->student_id)
                ->firstOrFail();
        }

        $complaint = Complaint::create([
            'parent_id'  => $parentId,
            'student_id' => $request->student_id,
            'subject'    => $request->subject,
            'body'       => $request->body,
        ]);

        return response()->json($complaint->load('student.user'), 201);
    }

    /**
     * GET /parent/{parentId}/complaints/{id}
     */
    public function show(int $parentId, int $id)
    {
        $complaint = Complaint::where('complaint_id', $id)
            ->where('parent_id', $parentId)
            ->with('student.user')
            ->firstOrFail();

        return response()->json($complaint);
    }
}
