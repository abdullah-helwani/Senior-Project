<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\SalaryPayment;
use Illuminate\Http\Request;

class SalaryController extends Controller
{
    /**
     * GET /teacher/{teacherId}/salary
     *
     * List salary payments for the given teacher.
     * Filters: year (YYYY)
     */
    public function index(int $teacherId, Request $request)
    {
        $query = SalaryPayment::where('teacher_id', $teacherId);

        if ($request->filled('year')) {
            $query->whereRaw("to_char(periodmonth, 'YYYY') = ?", [$request->year]);
        }

        $payments = $query->orderByDesc('periodmonth')->get();

        return response()->json([
            'teacher_id' => $teacherId,
            'total_paid' => (float) $payments->sum('amount'),
            'count'      => $payments->count(),
            'payments'   => $payments,
        ]);
    }

    /**
     * GET /teacher/{teacherId}/salary/{id}
     */
    public function show(int $teacherId, int $id)
    {
        $payment = SalaryPayment::where('teacher_id', $teacherId)
            ->where('salarypayment_id', $id)
            ->firstOrFail();

        return response()->json($payment);
    }
}
