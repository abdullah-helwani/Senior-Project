<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HomeworkSubmission extends Model
{
    protected $table = 'homeworksubmission';
    protected $primaryKey = 'submission_id';
    public $timestamps = false;

    protected $fillable = [
        'homework_id',
        'student_id',
        'submittedat',
        'score',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'submittedat' => 'datetime',
            'score'       => 'float',
        ];
    }

    public function homework()
    {
        return $this->belongsTo(Homework::class, 'homework_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id')->with('user');
    }
}
