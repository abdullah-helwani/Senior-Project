<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Stripe\Stripe;
use Stripe\Checkout\Session as StripeSession;

class StripeController extends Controller
{
    public function __construct()
    {
        Stripe::setApiKey(config('stripe.secret'));
    }

    /**
     * POST /parent/{parentId}/payments/checkout
     *
     * Create a Stripe Checkout Session for an invoice.
     * Body: { "invoice_id": 1, "success_url": "https://...", "cancel_url": "https://..." }
     */
    public function checkout(int $parentId, Request $request)
    {
        $request->validate([
            'invoice_id'  => 'required|exists:invoice,invoice_id',
            'success_url' => 'required|url',
            'cancel_url'  => 'required|url',
        ]);

        $invoice = Invoice::with('account.student.user', 'account.feePlan')
            ->where('invoice_id', $request->invoice_id)
            ->firstOrFail();

        // Verify the parent is a guardian of this student
        $isGuardian = DB::table('studentguardian')
            ->where('parent_id', $parentId)
            ->where('student_id', $invoice->account->student_id)
            ->exists();

        if (! $isGuardian) {
            return response()->json(['message' => 'Not your child.'], 403);
        }

        if ($invoice->status === 'paid') {
            return response()->json(['message' => 'This invoice is already fully paid.'], 422);
        }

        if ($invoice->status === 'cancelled') {
            return response()->json(['message' => 'Cannot pay a cancelled invoice.'], 422);
        }

        // Calculate outstanding amount
        $paid = (float) $invoice->payments()->where('status', 'completed')->sum('amount');
        $outstanding = (float) $invoice->totalamount - $paid;

        if ($outstanding <= 0) {
            return response()->json(['message' => 'No outstanding balance on this invoice.'], 422);
        }

        $studentName = $invoice->account->student->user->name;
        $feePlanName = $invoice->account->feePlan->name ?? 'School Fee';

        // Create Stripe Checkout Session
        $session = StripeSession::create([
            'payment_method_types' => ['card'],
            'line_items' => [[
                'price_data' => [
                    'currency'     => 'usd',
                    'unit_amount'  => (int) round($outstanding * 100), // Stripe uses cents
                    'product_data' => [
                        'name'        => "Invoice #{$invoice->invoice_id} — {$feePlanName}",
                        'description' => "Payment for {$studentName}",
                    ],
                ],
                'quantity' => 1,
            ]],
            'mode' => 'payment',
            'success_url' => $request->success_url . '?session_id={CHECKOUT_SESSION_ID}',
            'cancel_url'  => $request->cancel_url,
            'metadata' => [
                'invoice_id' => $invoice->invoice_id,
                'parent_id'  => $parentId,
                'amount'     => $outstanding,
            ],
        ]);

        // Create a pending payment record
        Payment::create([
            'invoice_id'         => $invoice->invoice_id,
            'parent_id'          => $parentId,
            'amount'             => $outstanding,
            'method'             => 'card',
            'stripe_session_id'  => $session->id,
            'status'             => 'pending',
            'paidat'             => now(),
        ]);

        return response()->json([
            'checkout_url' => $session->url,
            'session_id'   => $session->id,
            'amount'       => $outstanding,
        ]);
    }

    /**
     * GET /parent/{parentId}/payments/checkout/{sessionId}/status
     *
     * Check the status of a Stripe Checkout Session.
     */
    public function status(int $parentId, string $sessionId)
    {
        $payment = Payment::where('stripe_session_id', $sessionId)
            ->where('parent_id', $parentId)
            ->firstOrFail();

        return response()->json([
            'status'     => $payment->status,
            'amount'     => $payment->amount,
            'invoice_id' => $payment->invoice_id,
        ]);
    }
}
