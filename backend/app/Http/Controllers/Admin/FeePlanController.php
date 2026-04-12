<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeePlan;
use Illuminate\Http\Request;

class FeePlanController extends Controller
{
    /**
     * GET /admin/fee-plans
     *
     * List fee plans. Filters: schoolyear_id
     */
    public function index(Request $request)
    {
        $query = FeePlan::with('schoolYear');

        if ($request->filled('schoolyear_id')) {
            $query->where('schoolyear_id', $request->schoolyear_id);
        }

        $plans = $query->orderByDesc('feeplan_id')
            ->paginate($request->input('per_page', 20));

        return response()->json($plans);
    }

    /**
     * POST /admin/fee-plans
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'schoolyear_id' => 'required|exists:schoolyear,schoolyearid',
            'name'          => 'required|string|max:255',
            'totalamount'   => 'required|numeric|min:0',
        ]);

        $plan = FeePlan::create($data);

        return response()->json($plan->load('schoolYear'), 201);
    }

    /**
     * GET /admin/fee-plans/{id}
     */
    public function show(int $id)
    {
        $plan = FeePlan::where('feeplan_id', $id)
            ->with(['schoolYear', 'studentFeePlans.student.user'])
            ->firstOrFail();

        return response()->json($plan);
    }

    /**
     * PUT /admin/fee-plans/{id}
     */
    public function update(int $id, Request $request)
    {
        $plan = FeePlan::where('feeplan_id', $id)->firstOrFail();

        $data = $request->validate([
            'schoolyear_id' => 'sometimes|exists:schoolyear,schoolyearid',
            'name'          => 'sometimes|string|max:255',
            'totalamount'   => 'sometimes|numeric|min:0',
        ]);

        $plan->update($data);

        return response()->json($plan->load('schoolYear'));
    }

    /**
     * DELETE /admin/fee-plans/{id}
     */
    public function destroy(int $id)
    {
        $plan = FeePlan::where('feeplan_id', $id)->firstOrFail();

        if ($plan->studentFeePlans()->exists()) {
            return response()->json([
                'message' => 'Cannot delete this fee plan: it is assigned to one or more students.',
            ], 422);
        }

        $plan->delete();

        return response()->json(['message' => 'Fee plan removed successfully.']);
    }
}
