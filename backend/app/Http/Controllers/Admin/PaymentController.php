<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
    /**
     * GET /admin/payments
     *
     * List payments. Filters: invoice_id, parent_id, student_id, method,
     * paid_from, paid_to
     */
    public function index(Request $request)
    {
        $query = Payment::with([
            'invoice.account.student.user',
            'guardian.user',
        ]);

        if ($request->filled('invoice_id')) {
            $query->where('invoice_id', $request->invoice_id);
        }

        if ($request->filled('parent_id')) {
            $query->where('parent_id', $request->parent_id);
        }

        if ($request->filled('student_id')) {
            $query->whereHas('invoice.account', function ($q) use ($request) {
                $q->where('student_id', $request->student_id);
            });
        }

        if ($request->filled('method')) {
            $query->where('method', $request->method);
        }

        if ($request->filled('paid_from')) {
            $query->where('paidat', '>=', $request->paid_from);
        }

        if ($request->filled('paid_to')) {
            $query->where('paidat', '<=', $request->paid_to);
        }

        $payments = $query->orderByDesc('paidat')
            ->paginate($request->input('per_page', 20));

        return response()->json($payments);
    }

    /**
     * POST /admin/payments
     *
     * Record a payment against an invoice. Transactionally:
     *   - validates amount ≤ outstanding on invoice
     *   - verifies the parent is a guardian of the invoiced student
     *   - updates invoice.status (unpaid | partial | paid)
     *   - decrements the student's fee account balance
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'invoice_id' => 'required|exists:invoice,invoice_id',
            'parent_id'  => 'required|exists:parent,parent_id',
            'amount'     => 'required|numeric|min:0.01',
            'method'     => 'required|in:cash,card,bank_transfer,cheque',
            'paidat'     => 'nullable|date',
        ]);

        return DB::transaction(function () use ($data) {
            // Lock the invoice row so concurrent payments can't race
            $invoice = Invoice::where('invoice_id', $data['invoice_id'])
                ->lockForUpdate()
                ->with('account')
                ->firstOrFail();

            if ($invoice->status === 'cancelled') {
                return response()->json([
                    'message' => 'Cannot record a payment against a cancelled invoice.',
                ], 422);
            }

            // Verify the parent is a guardian of the invoiced student
            $isGuardian = DB::table('studentguardian')
                ->where('parent_id', $data['parent_id'])
                ->where('student_id', $invoice->account->student_id)
                ->exists();

            if (! $isGuardian) {
                return response()->json([
                    'message' => 'This parent is not a guardian of the invoiced student.',
                ], 422);
            }

            // Enforce: payment cannot exceed outstanding
            $paidTotal   = (float) $invoice->payments()->sum('amount');
            $outstanding = (float) $invoice->totalamount - $paidTotal;

            if ((float) $data['amount'] > $outstanding + 0.00001) {
                return response()->json([
                    'message'     => 'Payment amount exceeds the invoice outstanding balance.',
                    'outstanding' => round($outstanding, 2),
                ], 422);
            }

            // Create the payment
            $payment = Payment::create([
                'invoice_id' => $data['invoice_id'],
                'parent_id'  => $data['parent_id'],
                'amount'     => $data['amount'],
                'method'     => $data['method'],
                'paidat'     => $data['paidat'] ?? now(),
            ]);

            // Recalculate invoice status
            $newPaid = $paidTotal + (float) $data['amount'];
            if ($newPaid + 0.00001 >= (float) $invoice->totalamount) {
                $invoice->status = 'paid';
            } elseif ($newPaid > 0) {
                $invoice->status = 'partial';
            } else {
                $invoice->status = 'unpaid';
            }
            $invoice->save();

            // Decrement the account balance
            $account = $invoice->account;
            $account->balance = max(0, (float) $account->balance - (float) $data['amount']);
            $account->save();

            return response()->json(
                $payment->load(['invoice.account.student.user', 'guardian.user']),
                201
            );
        });
    }

    /**
     * GET /admin/payments/{id}
     */
    public function show(int $id)
    {
        $payment = Payment::where('payment_id', $id)
            ->with(['invoice.account.student.user', 'guardian.user'])
            ->firstOrFail();

        return response()->json($payment);
    }

    /**
     * DELETE /admin/payments/{id}
     *
     * Void a payment. Reverses the balance + invoice status changes.
     */
    public function destroy(int $id)
    {
        return DB::transaction(function () use ($id) {
            $payment = Payment::where('payment_id', $id)->lockForUpdate()->firstOrFail();

            $invoice = Invoice::where('invoice_id', $payment->invoice_id)
                ->lockForUpdate()
                ->with('account')
                ->firstOrFail();

            $amount = (float) $payment->amount;

            // Delete payment first so sums are correct
            $payment->delete();

            // Recalculate invoice status from remaining payments
            $remainingPaid = (float) $invoice->payments()->sum('amount');
            if ($remainingPaid + 0.00001 >= (float) $invoice->totalamount) {
                $invoice->status = 'paid';
            } elseif ($remainingPaid > 0) {
                $invoice->status = 'partial';
            } else {
                $invoice->status = 'unpaid';
            }
            $invoice->save();

            // Restore the account balance
            $account = $invoice->account;
            $account->balance = (float) $account->balance + $amount;
            $account->save();

            return response()->json(['message' => 'Payment voided successfully.']);
        });
    }
}
