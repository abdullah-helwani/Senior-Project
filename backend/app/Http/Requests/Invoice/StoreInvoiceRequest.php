<?php

namespace App\Http\Requests\Invoice;

use Illuminate\Foundation\Http\FormRequest;

class StoreInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_id'  => 'required|exists:studentfeeplan,account_id',
            'issued_date' => 'nullable|date',
            'due_date'    => 'required|date',
            'totalamount' => 'required|numeric|min:0',
            'status'      => 'nullable|in:unpaid,partial,paid,cancelled',
            'notes'       => 'nullable|string',
        ];
    }
}
