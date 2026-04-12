<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Teacher extends Model
{
    protected $fillable = [
        'user_id',
        'date_of_birth',
        'gender',
        'address',
        'hire_date',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'hire_date'     => 'date',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function assignments()
    {
        return $this->hasMany(TeacherAssignment::class, 'teacher_id', 'id');
    }

    public function subjects()
    {
        return $this->belongsToMany(Subject::class, 'teacherassignment', 'teacher_id', 'subject_id')
                    ->distinct();
    }

    public function salaryPayments()
    {
        return $this->hasMany(SalaryPayment::class, 'teacher_id', 'id');
    }
}
