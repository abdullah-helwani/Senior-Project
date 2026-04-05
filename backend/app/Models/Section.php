<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Section extends Model
{
    protected $table = 'section';
    protected $primaryKey = 'section_id';

    // Your section table uses class_id, not school_class_id
    protected $fillable = ['class_id', 'name'];

    public function schoolClass()
    {
        return $this->belongsTo(SchoolClass::class, 'class_id', 'class_id');
    }

    public function enrollments()
    {
        return $this->hasMany(Enrollment::class, 'section_id', 'section_id');
    }

    public function teacherAssignments()
    {
        return $this->hasMany(TeacherAssignment::class, 'section_id', 'section_id');
    }
}
