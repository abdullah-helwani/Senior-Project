<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SalaryPayment extends Model
{
    protected $table = 'salarypayment';
    protected $primaryKey = 'salarypayment_id';
    public $timestamps = false;

    protected $fillable = [
        'teacher_id',
        'amount',
        'periodmonth',
        'paidat',
    ];

    protected function casts(): array
    {
        return [
            'amount'      => 'decimal:2',
            'periodmonth' => 'date',
            'paidat'      => 'datetime',
        ];
    }

    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id', 'id');
    }
}
