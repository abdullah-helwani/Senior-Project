<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

// Named Guardian because "Parent" is a reserved word in PHP
class Guardian extends Model
{
    protected $table = 'parent';
    protected $primaryKey = 'parent_id';
    public $timestamps = false;

    protected $fillable = ['user_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function studentLinks()
    {
        return $this->hasMany(StudentGuardian::class, 'parent_id', 'parent_id');
    }

    public function students()
    {
        return $this->hasManyThrough(
            Student::class,
            StudentGuardian::class,
            'parent_id',   // FK on studentguardian
            'id',          // FK on students
            'parent_id',   // local key on parent
            'student_id'   // local key on studentguardian
        );
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'parent_id', 'parent_id');
    }
}
