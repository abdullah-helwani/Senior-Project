<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\VacationRequest;
use Illuminate\Http\Request;

class VacationRequestController extends Controller
{
    /**
     * GET /admin/vacation-requests
     *
     * List vacation requests. Filters: teacher_id, status (pending|approved|rejected)
     */
    public function index(Request $request)
    {
        $query = VacationRequest::with('teacher.user');

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('from')) {
            $query->where('start_date', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('end_date', '<=', $request->to);
        }

        $requests = $query->orderByDesc('start_date')
            ->paginate($request->input('per_page', 20));

        return response()->json($requests);
    }

    /**
     * GET /admin/vacation-requests/{id}
     */
    public function show(int $id)
    {
        $vacation = VacationRequest::where('vacation_id', $id)
            ->with(['teacher.user', 'approvedByAdmin.user'])
            ->firstOrFail();

        return response()->json($vacation);
    }

    /**
     * PUT /admin/vacation-requests/{id}
     *
     * Approve or reject a vacation request.
     */
    public function update(int $id, Request $request)
    {
        $vacation = VacationRequest::where('vacation_id', $id)->firstOrFail();

        $data = $request->validate([
            'status' => 'required|in:approved,rejected',
        ]);

        $admin = Admin::where('user_id', auth()->id())->firstOrFail();

        $vacation->update([
            'status'             => $data['status'],
            'approvedbyadmin_id' => $admin->admin_id,
        ]);

        return response()->json($vacation->load(['teacher.user', 'approvedByAdmin.user']));
    }

    /**
     * DELETE /admin/vacation-requests/{id}
     */
    public function destroy(int $id)
    {
        VacationRequest::where('vacation_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Vacation request deleted successfully.']);
    }
}
