<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VacationRequest extends Model
{
    protected $table = 'vacationrequest';
    protected $primaryKey = 'vacation_id';
    public $timestamps = false;

    protected $fillable = [
        'teacher_id',
        'start_date',
        'end_date',
        'status',
        'approvedbyadmin_id',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date'   => 'date',
        ];
    }

    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id', 'id');
    }

    public function approvedByAdmin()
    {
        return $this->belongsTo(Admin::class, 'approvedbyadmin_id', 'admin_id');
    }
}
