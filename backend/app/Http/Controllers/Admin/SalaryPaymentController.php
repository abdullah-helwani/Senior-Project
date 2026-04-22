<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SalaryPayment;
use Illuminate\Http\Request;

class SalaryPaymentController extends Controller
{
    /**
     * Normalize input to "YYYY-MM".
     * Accepts "YYYY-MM", "YYYY-MM-DD", or any date-parseable string.
     */
    private function toPeriodMonth(string $value): string
    {
        if (preg_match('/^\d{4}-\d{2}$/', $value)) {
            return $value;
        }

        return substr((string) strtotime($value)
            ? date('Y-m', strtotime($value))
            : $value, 0, 7);
    }

    /**
     * GET /admin/salary-payments
     *
     * List salary payments. Filters: teacher_id, period_month (YYYY-MM), from, to
     */
    public function index(Request $request)
    {
        $query = SalaryPayment::with('teacher.user');

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('period_month')) {
            // periodmonth is VARCHAR(7) stored as "YYYY-MM" — direct string match
            $query->where('periodmonth', $this->toPeriodMonth($request->period_month));
        }

        if ($request->filled('from')) {
            $query->where('paidat', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('paidat', '<=', $request->to);
        }

        $payments = $query->orderByDesc('paidat')
            ->paginate($request->input('per_page', 20));

        return response()->json($payments);
    }

    /**
     * POST /admin/salary-payments
     *
     * Record a salary payment for a teacher.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'teacher_id'   => 'required|exists:teachers,id',
            'amount'       => 'required|numeric|min:0',
            'period_month' => 'required|string',
            'paidat'       => 'nullable|date',
        ]);

        $period = $this->toPeriodMonth($data['period_month']);

        // Prevent duplicate salary for the same teacher in the same period month
        $exists = SalaryPayment::where('teacher_id', $data['teacher_id'])
            ->where('periodmonth', $period)
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'A salary payment already exists for this teacher in this period month.',
            ], 422);
        }

        $payment = SalaryPayment::create([
            'teacher_id'  => $data['teacher_id'],
            'amount'      => $data['amount'],
            'periodmonth' => $period,
            'paidat'      => $data['paidat'] ?? now(),
        ]);

        return response()->json($payment->load('teacher.user'), 201);
    }

    /**
     * GET /admin/salary-payments/{id}
     */
    public function show(int $id)
    {
        $payment = SalaryPayment::where('salarypayment_id', $id)
            ->with('teacher.user')
            ->firstOrFail();

        return response()->json($payment);
    }

    /**
     * PUT /admin/salary-payments/{id}
     */
    public function update(int $id, Request $request)
    {
        $payment = SalaryPayment::where('salarypayment_id', $id)->firstOrFail();

        $data = $request->validate([
            'amount'       => 'sometimes|numeric|min:0',
            'period_month' => 'sometimes|string',
            'paidat'       => 'sometimes|date',
        ]);

        if (array_key_exists('period_month', $data)) {
            $data['periodmonth'] = $this->toPeriodMonth($data['period_month']);
            unset($data['period_month']);
        }

        $payment->update($data);

        return response()->json($payment->load('teacher.user'));
    }

    /**
     * DELETE /admin/salary-payments/{id}
     */
    public function destroy(int $id)
    {
        SalaryPayment::where('salarypayment_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Salary payment removed successfully.']);
    }
}