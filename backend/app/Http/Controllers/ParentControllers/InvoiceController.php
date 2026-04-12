<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InvoiceController extends Controller
{
    /**
     * GET /parent/{parentId}/invoices
     *
     * List invoices for all children linked to this parent.
     * Filters: student_id, status
     */
    public function index(int $parentId, Request $request)
    {
        // Get all student IDs linked to this parent
        $childIds = DB::table('studentguardian')
            ->where('parent_id', $parentId)
            ->pluck('student_id');

        $query = Invoice::with([
            'account.student.user',
            'account.feePlan.schoolYear',
        ])->whereHas('account', function ($q) use ($childIds) {
            $q->whereIn('student_id', $childIds);
        });

        if ($request->filled('student_id')) {
            // Ensure the requested student is actually their child
            if (! $childIds->contains((int) $request->student_id)) {
                return response()->json(['message' => 'Not your child.'], 403);
            }
            $query->whereHas('account', function ($q) use ($request) {
                $q->where('student_id', $request->student_id);
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $invoices = $query->orderByDesc('due_date')->get();

        // Attach outstanding + paid totals per invoice
        $enriched = $invoices->map(function ($inv) {
            $paid = (float) $inv->payments()->sum('amount');
            return [
                'invoice_id'  => $inv->invoice_id,
                'student'     => [
                    'id'   => $inv->account->student->id,
                    'name' => $inv->account->student->user->name,
                ],
                'fee_plan'    => $inv->account->feePlan->name ?? null,
                'school_year' => $inv->account->feePlan->schoolYear->name ?? null,
                'due_date'    => $inv->due_date,
                'totalamount' => (float) $inv->totalamount,
                'paid_total'  => $paid,
                'outstanding' => max(0, (float) $inv->totalamount - $paid),
                'status'      => $inv->status,
            ];
        });

        return response()->json([
            'total'       => $enriched->count(),
            'outstanding' => $enriched->sum('outstanding'),
            'invoices'    => $enriched,
        ]);
    }

    /**
     * GET /parent/{parentId}/invoices/{id}
     */
    public function show(int $parentId, int $id)
    {
        $invoice = Invoice::where('invoice_id', $id)
            ->with([
                'account.student.user',
                'account.feePlan.schoolYear',
                'payments' => fn ($q) => $q->orderByDesc('paidat'),
                'payments.guardian.user',
            ])
            ->firstOrFail();

        // Verify the invoice belongs to one of this parent's children
        $isChild = DB::table('studentguardian')
            ->where('parent_id', $parentId)
            ->where('student_id', $invoice->account->student_id)
            ->exists();

        if (! $isChild) {
            return response()->json(['message' => 'Not your child.'], 403);
        }

        $paid        = (float) $invoice->payments->sum('amount');
        $outstanding = max(0, (float) $invoice->totalamount - $paid);

        return response()->json([
            'invoice'     => $invoice,
            'paid_total'  => $paid,
            'outstanding' => $outstanding,
        ]);
    }
}
