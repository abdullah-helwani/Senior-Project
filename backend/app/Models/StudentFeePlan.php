<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentFeePlan extends Model
{
    protected $table = 'studentfeeplan';
    protected $primaryKey = 'account_id';
    public $timestamps = false;

    protected $fillable = [
        'student_id',
        'feeplan_id',
        'balance',
    ];

    protected function casts(): array
    {
        return [
            'balance' => 'decimal:2',
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
}
