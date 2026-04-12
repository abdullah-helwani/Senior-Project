<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FeePlan extends Model
{
    protected $table = 'feeplan';
    protected $primaryKey = 'feeplan_id';
    public $timestamps = false;

    protected $fillable = [
        'schoolyear_id',
        'totalamount',
        'name',
    ];

    protected function casts(): array
    {
        return [
            'totalamount' => 'decimal:2',
        ];
    }

    public function schoolYear()
    {
        return $this->belongsTo(SchoolYear::class, 'schoolyear_id', 'schoolyearid');
    }

    public function studentFeePlans()
    {
        return $this->hasMany(StudentFeePlan::class, 'feeplan_id', 'feeplan_id');
    }
}
