<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Homework extends Model
{
    protected $fillable = [
        'subject_id',
        'teacher_id',
        'section_id',
        'title',
        'description',
        'due_date',
    ];

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
        ];
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class, 'subject_id', 'id');
    }

    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id', 'id')->with('user');
    }

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id', 'section_id')->with('schoolClass');
    }

    public function submissions()
    {
        return $this->hasMany(HomeworkSubmission::class, 'homework_id');
    }
}
