<?php

namespace App\Http\Controllers\Webhook;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Stripe\Stripe;
use Stripe\Webhook;

class StripeWebhookController extends Controller
{
    public function handle(Request $request)
    {
        Stripe::setApiKey(config('stripe.secret'));

        $payload   = $request->getContent();
        $sigHeader = $request->header('Stripe-Signature');

        try {
            $event = Webhook::constructEvent(
                $payload,
                $sigHeader,
                config('stripe.webhook_secret')
            );
        } catch (\Exception $e) {
            Log::error('Stripe webhook signature verification failed.', ['error' => $e->getMessage()]);
            return response()->json(['error' => 'Invalid signature.'], 400);
        }

        switch ($event->type) {
            case 'checkout.session.completed':
                $this->handleCheckoutCompleted($event->data->object);
                break;

            case 'checkout.session.expired':
                $this->handleCheckoutExpired($event->data->object);
                break;

            default:
                Log::info("Unhandled Stripe event: {$event->type}");
        }

        return response()->json(['status' => 'ok']);
    }

    private function handleCheckoutCompleted($session): void
    {
        $payment = Payment::where('stripe_session_id', $session->id)->first();

        if (! $payment || $payment->status === 'completed') {
            return; // Already processed or not found
        }

        DB::transaction(function () use ($payment, $session) {
            // Mark payment as completed
            $payment->update([
                'status'                => 'completed',
                'stripe_payment_intent' => $session->payment_intent,
                'paidat'                => now(),
            ]);

            // Update invoice status
            $invoice = Invoice::where('invoice_id', $payment->invoice_id)
                ->lockForUpdate()
                ->with('account')
                ->firstOrFail();

            $paidTotal = (float) $invoice->payments()->where('status', 'completed')->sum('amount');

            if ($paidTotal + 0.00001 >= (float) $invoice->totalamount) {
                $invoice->status = 'paid';
            } elseif ($paidTotal > 0) {
                $invoice->status = 'partial';
            }
            $invoice->save();

            // Decrement account balance
            $account = $invoice->account;
            $account->balance = max(0, (float) $account->balance - (float) $payment->amount);
            $account->save();
        });

        Log::info("Stripe payment completed for invoice #{$payment->invoice_id}", [
            'payment_id' => $payment->payment_id,
            'amount'     => $payment->amount,
        ]);
    }

    private function handleCheckoutExpired($session): void
    {
        $payment = Payment::where('stripe_session_id', $session->id)
            ->where('status', 'pending')
            ->first();

        if ($payment) {
            $payment->update(['status' => 'failed']);
            Log::info("Stripe checkout expired for session {$session->id}");
        }
    }
}
