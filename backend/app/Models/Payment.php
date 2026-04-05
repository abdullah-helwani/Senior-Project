<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $table = 'payment';
    protected $primaryKey = 'payment_id';
    public $timestamps = false;

    protected $fillable = [
        'invoice_id',
        'parent_id',
        'amount',
        'method',
        'paidat',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'paidat' => 'datetime',
        ];
    }

    public function invoice()
    {
        return $this->belongsTo(Invoice::class, 'invoice_id', 'invoice_id');
    }

    public function guardian()
    {
        return $this->belongsTo(Guardian::class, 'parent_id', 'parent_id');
    }
}
