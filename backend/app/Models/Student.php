<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = [
        'user_id',
        'date_of_birth',
        'gender',
        'address',
        'enrollment_date',
        'graduation_year',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth'   => 'date',
            'enrollment_date' => 'date',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function enrollments()
    {
        return $this->hasMany(Enrollment::class, 'student_id', 'id');
    }

    public function activeEnrollment()
    {
        return $this->hasOne(Enrollment::class, 'student_id', 'id')
            ->where('status', 'active')
            ->latestOfMany('enrollment_id');
    }

    public function feeAccounts()
    {
        return $this->hasMany(StudentFeePlan::class, 'student_id', 'id');
    }
}
