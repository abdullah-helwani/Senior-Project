<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\StudentFeePlan;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    /**
     * GET /admin/invoices/by-student
     *
     * Aggregated billing view — one row per student with all invoices and totals.
     * Filters: status (overall), search (student name), overdue (bool), schoolyear_id
     */
    public function byStudent(Request $request)
    {
        $invoiceQuery = Invoice::with([
            'account.student.user',
            'account.student.enrollments.section.schoolClass',
            'account.student.guardians.user',
            'account.feePlan',
            'payments',
        ]);

        if ($request->filled('schoolyear_id')) {
            $invoiceQuery->whereHas('account.feePlan', fn ($q) =>
                $q->where('schoolyear_id', $request->schoolyear_id));
        }

        $all = $invoiceQuery->get();
        $today = now()->toDateString();

        $grouped = $all->groupBy(fn ($inv) => $inv->account?->student_id)
            ->map(function ($invoices, $studentId) use ($today) {
                $first      = $invoices->first();
                $student    = $first->account?->student;
                $enrollment = $student?->enrollments->first();
                $guardian   = $student?->guardians->first();

                $items = $invoices->map(function ($inv) use ($today) {
                    $paidSum   = (float) $inv->payments->sum('amount');
                    $total     = (float) $inv->totalamount;
                    $remaining = max(0, $total - $paidSum);
                    $isOverdue = $inv->status !== 'paid'
                              && $inv->status !== 'cancelled'
                              && $inv->due_date && $inv->due_date->toDateString() < $today;

                    return [
                        'invoice_id'    => $inv->invoice_id,
                        'account_id'    => $inv->account_id,
                        'fee_plan_name' => optional($inv->account?->feePlan)->name,
                        'due_date'      => $inv->due_date?->format('Y-m-d'),
                        'total'         => $total,
                        'paid'          => $paidSum,
                        'remaining'     => $remaining,
                        'status'        => $inv->status,
                        'is_overdue'    => $isOverdue,
                        'payments'      => $inv->payments->map(fn ($p) => [
                            'payment_id' => $p->payment_id,
                            'amount'     => (float) $p->amount,
                            'method'     => $p->method,
                            'paidat'     => $p->paidat,
                        ])->values(),
                    ];
                })->values();

                $totalBilled    = $items->sum('total');
                $totalPaid      = $items->sum('paid');
                $totalRemaining = $items->sum('remaining');

                $overallStatus = 'unpaid';
                if ($totalBilled > 0 && $totalPaid >= $totalBilled) $overallStatus = 'paid';
                elseif ($totalPaid > 0) $overallStatus = 'partial';

                $overdueCount = $items->where('is_overdue', true)->count();
                $paidCount    = $items->where('status', 'paid')->count();
                $partialCount = $items->where('status', 'partial')->count();
                $unpaidCount  = $items->where('status', 'unpaid')->count();

                // Earliest unpaid due date
                $nextDue = $items->where('status', '!=', 'paid')
                                 ->where('status', '!=', 'cancelled')
                                 ->pluck('due_date')->filter()->sort()->first();

                // Latest payment date
                $lastPayment = $invoices->flatMap->payments
                    ->sortByDesc('paidat')->first()?->paidat;

                return [
                    'student_id'        => $studentId,
                    'student_name'      => $student?->user?->name ?? "#{$studentId}",
                    'student_class'     => $enrollment ? (optional(optional($enrollment->section)->schoolClass)->name . ' — ' . optional($enrollment->section)->name) : null,
                    'parent_name'       => $guardian?->user?->name,
                    'parent_phone'      => $guardian?->user?->phone,
                    'invoices'          => $items,
                    'total_billed'      => $totalBilled,
                    'total_paid'        => $totalPaid,
                    'total_remaining'   => $totalRemaining,
                    'overall_status'    => $overallStatus,
                    'invoice_count'     => $items->count(),
                    'overdue_count'     => $overdueCount,
                    'paid_count'        => $paidCount,
                    'partial_count'     => $partialCount,
                    'unpaid_count'      => $unpaidCount,
                    'next_due_date'     => $nextDue,
                    'last_payment_date' => $lastPayment,
                ];
            })->values();

        // Filter by overall status
        if ($request->filled('status')) {
            $grouped = $grouped->filter(fn ($s) => $s['overall_status'] === $request->status)->values();
        }

        // Filter overdue only
        if ($request->boolean('overdue')) {
            $grouped = $grouped->filter(fn ($s) => $s['overdue_count'] > 0)->values();
        }

        // Search by student name
        if ($request->filled('search')) {
            $term    = strtolower($request->search);
            $grouped = $grouped->filter(fn ($s) => str_contains(strtolower($s['student_name']), $term))->values();
        }

        // Sort: overdue first, then highest remaining
        $grouped = $grouped->sortByDesc(fn ($s) => [$s['overdue_count'], $s['total_remaining']])->values();

        // Manual pagination
        $perPage = (int) $request->input('per_page', 20);
        $page    = (int) $request->input('page', 1);
        $total   = $grouped->count();
        $items   = $grouped->slice(($page - 1) * $perPage, $perPage)->values();

        return response()->json([
            'data'         => $items,
            'total'        => $total,
            'per_page'     => $perPage,
            'current_page' => $page,
        ]);
    }

    /**
     * POST /admin/invoices/{id}/mark-paid
     *
     * Quick action: record full payment (or update status to paid).
     */
    public function markPaid(int $id, Request $request)
    {
        $invoice = Invoice::where('invoice_id', $id)
            ->with(['account.student.guardians', 'payments'])
            ->firstOrFail();

        $request->validate([
            'method'      => 'nullable|string|in:cash,card,bank_transfer,cheque',
            'guardian_id' => 'nullable|integer',
        ]);

        $paidSum   = (float) $invoice->payments->sum('amount');
        $remaining = max(0, (float) $invoice->totalamount - $paidSum);

        if ($remaining > 0) {
            // Find guardian if not provided
            $parentId = $request->guardian_id
                ?? optional($invoice->account?->student?->guardians?->first())->parent_id;

            if (! $parentId) {
                return response()->json([
                    'message' => 'Cannot record payment: no guardian linked to this student. Please link a parent first.',
                ], 422);
            }

            \App\Models\Payment::create([
                'invoice_id' => $invoice->invoice_id,
                'parent_id'  => $parentId,
                'amount'     => $remaining,
                'method'     => $request->method ?? 'cash',
                'paidat'     => now(),
                'status'     => 'completed',
            ]);
        }

        $invoice->update(['status' => 'paid']);

        // Sync the linked account
        if ($invoice->account) {
            $invoice->account->update([
                'paid_amount' => $invoice->totalamount,
                'balance'     => 0,
                'status'      => 'paid',
            ]);
        }

        return response()->json(['message' => 'Invoice marked as paid', 'invoice' => $invoice->fresh()]);
    }

    /**
     * GET /admin/invoices
     *
     * List invoices. Filters: status, overdue (bool), search (student name),
     * fee_type (tuition|bus|activity), issued_from, issued_to, due_from, due_to
     */
    public function index(Request $request)
    {
        $query = Invoice::with([
            'account.student.user',
            'account.student.guardians.user',
            'account.feePlan',
            'payments',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->boolean('overdue')) {
            $query->where('due_date', '<', now()->toDateString())
                  ->whereIn('status', ['unpaid', 'partial']);
        }

        if ($request->filled('issued_from')) $query->where('issued_date', '>=', $request->issued_from);
        if ($request->filled('issued_to'))   $query->where('issued_date', '<=', $request->issued_to);
        if ($request->filled('due_from'))    $query->where('due_date',    '>=', $request->due_from);
        if ($request->filled('due_to'))      $query->where('due_date',    '<=', $request->due_to);

        if ($request->filled('search')) {
            $term = strtolower($request->search);
            $query->whereHas('account.student.user', fn ($q) => $q->whereRaw('LOWER(name) like ?', ["%{$term}%"]));
        }

        if ($request->filled('fee_type')) {
            $type = strtolower($request->fee_type);
            $query->whereHas('account.feePlan', function ($q) use ($type) {
                if ($type === 'tuition')        $q->whereRaw('LOWER(name) like ?', ['%tuition%']);
                elseif ($type === 'bus')         $q->whereRaw('LOWER(name) like ?', ['%bus%']);
                elseif ($type === 'activity')    $q->where(function ($qq) {
                    $qq->whereRaw('LOWER(name) like ?', ['%activity%'])
                       ->orWhereRaw('LOWER(name) like ?', ['%lab%']);
                });
            });
        }

        $invoices = $query->orderByDesc('issued_date')
            ->orderByDesc('invoice_id')
            ->paginate($request->input('per_page', 20));

        // Augment each invoice with calculated paid/remaining + flattened display fields
        $today = now()->toDateString();
        $invoices->getCollection()->transform(function ($inv) use ($today) {
            $paid       = (float) $inv->payments->sum('amount');
            $total      = (float) $inv->totalamount;
            $remaining  = max(0, $total - $paid);
            $isOverdue  = $inv->status !== 'paid'
                       && $inv->status !== 'cancelled'
                       && $inv->due_date && $inv->due_date->toDateString() < $today;

            $student   = $inv->account?->student;
            $guardian  = $student?->guardians?->first();

            return [
                'invoice_id'    => $inv->invoice_id,
                'account_id'    => $inv->account_id,
                'issued_date'   => $inv->issued_date?->format('Y-m-d'),
                'due_date'      => $inv->due_date?->format('Y-m-d'),
                'totalamount'   => $total,
                'paid'          => $paid,
                'remaining'     => $remaining,
                'status'        => $inv->status,
                'is_overdue'    => $isOverdue,
                'notes'         => $inv->notes,
                'student_id'    => $student?->id,
                'student_name'  => $student?->user?->name,
                'parent_name'   => $guardian?->user?->name,
                'parent_phone'  => $guardian?->user?->phone,
                'fee_plan_name' => $inv->account?->feePlan?->name,
            ];
        });

        return response()->json($invoices);
    }

    /**
     * POST /admin/invoices
     *
     * Create a new invoice against a student's fee account.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'account_id'  => 'required|exists:studentfeeplan,account_id',
            'due_date'    => 'required|date',
            'totalamount' => 'required|numeric|min:0',
            'status'      => 'nullable|in:unpaid,partial,paid,cancelled',
        ]);

        $data['status'] = $data['status'] ?? 'unpaid';

        $invoice = Invoice::create($data);

        return response()->json(
            $invoice->load(['account.student.user', 'account.feePlan']),
            201
        );
    }

    /**
     * GET /admin/invoices/{id}
     *
     * Returns the invoice in printable-document shape with bill-to info,
     * line item, payment history, and outstanding balance.
     */
    public function show(int $id)
    {
        $invoice = Invoice::where('invoice_id', $id)
            ->with([
                'account.student.user',
                'account.student.enrollments.section.schoolClass',
                'account.student.guardians.user',
                'account.feePlan.schoolYear',
                'payments.guardian.user',
            ])
            ->firstOrFail();

        $paid        = (float) $invoice->payments->sum('amount');
        $outstanding = max(0, (float) $invoice->totalamount - $paid);

        $student    = $invoice->account?->student;
        $enrollment = $student?->enrollments->first();
        $guardian   = $student?->guardians?->first();

        return response()->json([
            'invoice' => [
                'invoice_id'  => $invoice->invoice_id,
                'issued_date' => $invoice->issued_date?->format('Y-m-d'),
                'due_date'    => $invoice->due_date?->format('Y-m-d'),
                'totalamount' => (float) $invoice->totalamount,
                'status'      => $invoice->status,
                'notes'       => $invoice->notes,
            ],
            'student' => [
                'student_id' => $student?->id,
                'name'       => $student?->user?->name,
                'class'      => $enrollment ? (optional(optional($enrollment->section)->schoolClass)->name . ' — ' . optional($enrollment->section)->name) : null,
                'address'    => $student?->address,
            ],
            'parent' => [
                'parent_id' => $guardian?->parent_id,
                'name'      => $guardian?->user?->name,
                'email'     => $guardian?->user?->email,
                'phone'     => $guardian?->user?->phone,
            ],
            'fee_plan' => [
                'name'        => $invoice->account?->feePlan?->name,
                'school_year' => $invoice->account?->feePlan?->schoolYear?->name,
            ],
            'payments' => $invoice->payments->map(fn ($p) => [
                'payment_id'  => $p->payment_id,
                'amount'      => (float) $p->amount,
                'method'      => $p->method,
                'paidat'      => $p->paidat,
                'parent_name' => optional($p->guardian)->user?->name,
            ])->values(),
            'paid_total'  => $paid,
            'outstanding' => $outstanding,
        ]);
    }

    /**
     * PUT /admin/invoices/{id}
     */
    public function update(int $id, Request $request)
    {
        $invoice = Invoice::where('invoice_id', $id)->firstOrFail();

        $data = $request->validate([
            'due_date'    => 'sometimes|date',
            'totalamount' => 'sometimes|numeric|min:0',
            'status'      => 'sometimes|in:unpaid,partial,paid,cancelled',
        ]);

        $invoice->update($data);

        return response()->json($invoice->load(['account.student.user', 'account.feePlan']));
    }

    /**
     * DELETE /admin/invoices/{id}
     */
    public function destroy(int $id)
    {
        $invoice = Invoice::where('invoice_id', $id)->firstOrFail();

        if ($invoice->payments()->exists()) {
            return response()->json([
                'message' => 'Cannot delete this invoice: payments have been recorded against it.',
            ], 422);
        }

        $invoice->delete();

        return response()->json(['message' => 'Invoice removed successfully.']);
    }
}
