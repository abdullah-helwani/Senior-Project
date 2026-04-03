<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use Illuminate\Http\Request;

class ComplaintController extends Controller
{
    /**
     * GET /admin/complaints
     *
     * List all complaints. Filters: status, parent_id, student_id
     */
    public function index(Request $request)
    {
        $query = Complaint::with(['guardian.user', 'student.user']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('parent_id')) {
            $query->where('parent_id', $request->parent_id);
        }

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        $complaints = $query->orderByDesc('created_at')
            ->paginate($request->input('per_page', 20));

        return response()->json($complaints);
    }

    /**
     * GET /admin/complaints/{id}
     */
    public function show(int $id)
    {
        $complaint = Complaint::with(['guardian.user', 'student.user'])
            ->where('complaint_id', $id)
            ->firstOrFail();

        return response()->json($complaint);
    }

    /**
     * PUT /admin/complaints/{id}
     *
     * Update status and/or reply to a complaint.
     * Body: { "status": "in_review|resolved|dismissed", "admin_reply": "..." }
     */
    public function update(int $id, Request $request)
    {
        $complaint = Complaint::where('complaint_id', $id)->firstOrFail();

        $request->validate([
            'status'      => 'sometimes|in:open,in_review,resolved,dismissed',
            'admin_reply' => 'sometimes|nullable|string',
        ]);

        $data = $request->only(['status', 'admin_reply']);

        if ($request->input('status') === 'resolved' || $request->input('status') === 'dismissed') {
            $data['resolved_at'] = now();
        }

        $complaint->update($data);

        return response()->json($complaint->load(['guardian.user', 'student.user']));
    }
}
