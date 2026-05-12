<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentFeePlan extends Model
{
    protected $table = 'studentfeeplan';
    protected $primaryKey = 'account_id';
    public $timestamps = true;

    protected $fillable = [
        'student_id',
        'feeplan_id',
        'balance',
        'paid_amount',
        'status',
        'due_date',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'balance'     => 'decimal:2',
            'paid_amount' => 'decimal:2',
            'due_date'    => 'date',
        ];
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id', 'id');
    }

    public function feePlan()
    {
        return $this->belongsTo(FeePlan::class, 'feeplan_id', 'feeplan_id');
    }

    public function invoices()
    {
        return $this->hasMany(Invoice::class, 'account_id', 'account_id');
    }

    /** Recompute status from paid_amount vs plan total. */
    public function syncStatus(): void
    {
        $total = (float) optional($this->feePlan)->totalamount ?? (float) $this->balance + (float) $this->paid_amount;
        $paid  = (float) $this->paid_amount;

        if ($paid <= 0) {
            $this->status = 'unpaid';
        } elseif ($paid >= $total) {
            $this->status = 'paid';
            $this->balance = 0;
        } else {
            $this->status = 'partial';
            $this->balance = $total - $paid;
        }
    }
}
