<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeePlan;
use App\Models\StudentFeePlan;
use Illuminate\Http\Request;

class StudentFeePlanController extends Controller
{
    /**
     * GET /admin/student-fee-plans
     *
     * List student fee accounts. Filters: student_id, feeplan_id, schoolyear_id
     */
    public function index(Request $request)
    {
        $query = StudentFeePlan::with(['student.user', 'feePlan.schoolYear']);

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('feeplan_id')) {
            $query->where('feeplan_id', $request->feeplan_id);
        }

        if ($request->filled('schoolyear_id')) {
            $query->whereHas('feePlan', function ($q) use ($request) {
                $q->where('schoolyear_id', $request->schoolyear_id);
            });
        }

        $accounts = $query->orderByDesc('account_id')
            ->paginate($request->input('per_page', 20));

        return response()->json($accounts);
    }

    /**
     * POST /admin/student-fee-plans
     *
     * Assign a fee plan to a student. Balance defaults to the plan's total amount
     * (full amount outstanding) unless explicitly overridden.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
            'feeplan_id' => 'required|exists:feeplan,feeplan_id',
            'balance'    => 'nullable|numeric|min:0',
        ]);

        // Prevent duplicate assignment of the same plan to the same student
        $exists = StudentFeePlan::where('student_id', $data['student_id'])
            ->where('feeplan_id', $data['feeplan_id'])
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'This student is already assigned to this fee plan.',
            ], 422);
        }

        // Default the balance to the full plan amount if not provided
        if (! array_key_exists('balance', $data) || $data['balance'] === null) {
            $plan = FeePlan::where('feeplan_id', $data['feeplan_id'])->firstOrFail();
            $data['balance'] = $plan->totalamount;
        }

        $account = StudentFeePlan::create($data);

        return response()->json(
            $account->load(['student.user', 'feePlan.schoolYear']),
            201
        );
    }

    /**
     * GET /admin/student-fee-plans/{id}
     */
    public function show(int $id)
    {
        $account = StudentFeePlan::where('account_id', $id)
            ->with(['student.user', 'feePlan.schoolYear', 'invoices'])
            ->firstOrFail();

        return response()->json($account);
    }

    /**
     * PUT /admin/student-fee-plans/{id}
     */
    public function update(int $id, Request $request)
    {
        $account = StudentFeePlan::where('account_id', $id)->firstOrFail();

        $data = $request->validate([
            'feeplan_id' => 'sometimes|exists:feeplan,feeplan_id',
            'balance'    => 'sometimes|numeric|min:0',
        ]);

        $account->update($data);

        return response()->json($account->load(['student.user', 'feePlan.schoolYear']));
    }

    /**
     * DELETE /admin/student-fee-plans/{id}
     */
    public function destroy(int $id)
    {
        $account = StudentFeePlan::where('account_id', $id)->firstOrFail();

        if ($account->invoices()->exists()) {
            return response()->json([
                'message' => 'Cannot delete this fee account: it has invoices attached.',
            ], 422);
        }

        $account->delete();

        return response()->json(['message' => 'Student fee account removed successfully.']);
    }
}
