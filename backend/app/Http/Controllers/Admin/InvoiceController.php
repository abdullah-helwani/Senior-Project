<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\StudentFeePlan;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    /**
     * GET /admin/invoices
     *
     * List invoices. Filters: account_id, student_id, status, overdue (bool),
     * due_from, due_to
     */
    public function index(Request $request)
    {
        $query = Invoice::with(['account.student.user', 'account.feePlan']);

        if ($request->filled('account_id')) {
            $query->where('account_id', $request->account_id);
        }

        if ($request->filled('student_id')) {
            $query->whereHas('account', function ($q) use ($request) {
                $q->where('student_id', $request->student_id);
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->boolean('overdue')) {
            $query->where('due_date', '<', now()->toDateString())
                  ->whereIn('status', ['unpaid', 'partial']);
        }

        if ($request->filled('due_from')) {
            $query->where('due_date', '>=', $request->due_from);
        }

        if ($request->filled('due_to')) {
            $query->where('due_date', '<=', $request->due_to);
        }

        $invoices = $query->orderByDesc('due_date')
            ->paginate($request->input('per_page', 20));

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
     * Shows invoice with payments + outstanding balance.
     */
    public function show(int $id)
    {
        $invoice = Invoice::where('invoice_id', $id)
            ->with([
                'account.student.user',
                'account.feePlan',
                'payments.guardian.user',
            ])
            ->firstOrFail();

        $paid        = (float) $invoice->payments->sum('amount');
        $outstanding = (float) $invoice->totalamount - $paid;

        return response()->json([
            'invoice'     => $invoice,
            'paid_total'  => $paid,
            'outstanding' => max(0, $outstanding),
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
