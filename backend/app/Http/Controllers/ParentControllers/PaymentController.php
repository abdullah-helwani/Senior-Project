<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    /**
     * GET /parent/{parentId}/payments
     *
     * List payment history made by this parent.
     * Filters: student_id, method, paid_from, paid_to
     */
    public function index(int $parentId, Request $request)
    {
        $query = Payment::where('parent_id', $parentId)
            ->with(['invoice.account.student.user']);

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

        $payments = $query->orderByDesc('paidat')->get();

        return response()->json([
            'total_paid' => (float) $payments->sum('amount'),
            'count'      => $payments->count(),
            'payments'   => $payments,
        ]);
    }

    /**
     * GET /parent/{parentId}/payments/{id}
     */
    public function show(int $parentId, int $id)
    {
        $payment = Payment::where('parent_id', $parentId)
            ->where('payment_id', $id)
            ->with(['invoice.account.student.user'])
            ->firstOrFail();

        return response()->json($payment);
    }
}
