<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Invoice extends Model
{
    protected $table = 'invoice';
    protected $primaryKey = 'invoice_id';
    public $timestamps = false;

    protected $fillable = [
        'account_id',
        'due_date',
        'totalamount',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'due_date'    => 'date',
            'totalamount' => 'decimal:2',
        ];
    }

    public function account()
    {
        return $this->belongsTo(StudentFeePlan::class, 'account_id', 'account_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'invoice_id', 'invoice_id');
    }
}
