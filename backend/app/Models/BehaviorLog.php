<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BehaviorLog extends Model
{
    protected $table = 'behaviorlog';
    protected $primaryKey = 'log_id';

    protected $fillable = [
        'student_id',
        'teacher_id',
        'section_id',
        'type',
        'title',
        'description',
        'date',
        'notify_parent',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'notify_parent' => 'boolean',
        ];
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id')->with('user');
    }

    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id')->with('user');
    }

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id', 'section_id')->with('schoolClass');
    }
}
