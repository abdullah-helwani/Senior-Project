<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeePlan;
use App\Models\StudentFeePlan;
use Illuminate\Http\Request;

class StudentFeePlanController extends Controller
{
    /**
     * GET /admin/student-fee-plans/by-student
     *
     * Returns one row per student with all their fee plans aggregated.
     * Filters: schoolyear_id, status (overall), search (student name)
     */
    public function byStudent(Request $request)
    {
        $query = StudentFeePlan::with(['student.user', 'feePlan.schoolYear']);

        if ($request->filled('schoolyear_id')) {
            $query->whereHas('feePlan', fn ($q) => $q->where('schoolyear_id', $request->schoolyear_id));
        }

        // Fetch all matching records, then group in PHP
        $all = $query->get();

        $grouped = $all->groupBy('student_id')->map(function ($accounts) {
            $student    = $accounts->first()->student;
            $totalFee   = $accounts->sum(fn ($a) => (float) optional($a->feePlan)->totalamount);
            $totalPaid  = $accounts->sum(fn ($a) => (float) $a->paid_amount);
            $totalBal   = $accounts->sum(fn ($a) => (float) $a->balance);

            $overallStatus = 'unpaid';
            if ($totalPaid >= $totalFee && $totalFee > 0) {
                $overallStatus = 'paid';
            } elseif ($totalPaid > 0) {
                $overallStatus = 'partial';
            }

            return [
                'student_id'     => $accounts->first()->student_id,
                'student_name'   => $student?->user?->name ?? "#{$accounts->first()->student_id}",
                'plans'          => $accounts->map(fn ($a) => [
                    'account_id'  => $a->account_id,
                    'feeplan_id'  => $a->feeplan_id,
                    'plan_name'   => optional($a->feePlan)->name,
                    'school_year' => optional(optional($a->feePlan)->schoolYear)->name,
                    'total'       => (float) optional($a->feePlan)->totalamount,
                    'paid'        => (float) $a->paid_amount,
                    'balance'     => (float) $a->balance,
                    'status'      => $a->status,
                    'due_date'    => $a->due_date?->format('Y-m-d'),
                    'notes'       => $a->notes,
                ])->values(),
                'total_fee'      => $totalFee,
                'total_paid'     => $totalPaid,
                'total_balance'  => $totalBal,
                'overall_status' => $overallStatus,
            ];
        })->values();

        // Filter by overall status after grouping
        if ($request->filled('status')) {
            $grouped = $grouped->filter(fn ($s) => $s['overall_status'] === $request->status)->values();
        }

        // Search by student name
        if ($request->filled('search')) {
            $term    = strtolower($request->search);
            $grouped = $grouped->filter(fn ($s) => str_contains(strtolower($s['student_name']), $term))->values();
        }

        // Manual pagination
        $perPage  = (int) $request->input('per_page', 20);
        $page     = (int) $request->input('page', 1);
        $total    = $grouped->count();
        $items    = $grouped->slice(($page - 1) * $perPage, $perPage)->values();

        return response()->json([
            'data'         => $items,
            'total'        => $total,
            'per_page'     => $perPage,
            'current_page' => $page,
        ]);
    }

    /**
     * GET /admin/student-fee-plans
     *
     * Filters: student_id, feeplan_id, schoolyear_id, status
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
            $query->whereHas('feePlan', fn ($q) => $q->where('schoolyear_id', $request->schoolyear_id));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $accounts = $query->orderByDesc('account_id')
            ->paginate($request->input('per_page', 20));

        return response()->json($accounts);
    }

    /**
     * POST /admin/student-fee-plans
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'student_id'  => 'required|exists:students,id',
            'feeplan_id'  => 'required|exists:feeplan,feeplan_id',
            'paid_amount' => 'nullable|numeric|min:0',
            'due_date'    => 'nullable|date',
            'notes'       => 'nullable|string|max:500',
        ]);

        $exists = StudentFeePlan::where('student_id', $data['student_id'])
            ->where('feeplan_id', $data['feeplan_id'])
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'This student is already assigned to this fee plan.',
            ], 422);
        }

        $plan = FeePlan::where('feeplan_id', $data['feeplan_id'])->firstOrFail();
        $paid = (float) ($data['paid_amount'] ?? 0);
        $total = (float) $plan->totalamount;

        $account = StudentFeePlan::create([
            'student_id'  => $data['student_id'],
            'feeplan_id'  => $data['feeplan_id'],
            'paid_amount' => $paid,
            'balance'     => max(0, $total - $paid),
            'status'      => $paid <= 0 ? 'unpaid' : ($paid >= $total ? 'paid' : 'partial'),
            'due_date'    => $data['due_date'] ?? null,
            'notes'       => $data['notes'] ?? null,
        ]);

        return response()->json($account->load(['student.user', 'feePlan.schoolYear']), 201);
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
        $account = StudentFeePlan::where('account_id', $id)
            ->with('feePlan')
            ->firstOrFail();

        $data = $request->validate([
            'paid_amount' => 'sometimes|numeric|min:0',
            'due_date'    => 'sometimes|nullable|date',
            'notes'       => 'sometimes|nullable|string|max:500',
        ]);

        if (isset($data['paid_amount'])) {
            $total = (float) $account->feePlan->totalamount;
            $paid  = (float) $data['paid_amount'];
            $data['balance'] = max(0, $total - $paid);
            $data['status']  = $paid <= 0 ? 'unpaid' : ($paid >= $total ? 'paid' : 'partial');
        }

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
                'message' => 'Cannot delete: this account has invoices attached.',
            ], 422);
        }

        $account->delete();

        return response()->json(['message' => 'Student fee account removed successfully.']);
    }
}
