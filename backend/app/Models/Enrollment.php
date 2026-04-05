<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Enrollment extends Model
{
    protected $table = 'enrollment';
    protected $primaryKey = 'enrollment_id';

    protected $fillable = ['student_id', 'section_id', 'status'];

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id', 'id');
    }

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id', 'section_id')->with('schoolClass');
    }
}
