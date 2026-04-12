<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentGuardian extends Model
{
    protected $table = 'studentguardian';
    protected $primaryKey = 'studentguardian_id';
    public $timestamps = false;

    protected $fillable = [
        'student_id',
        'parent_id',
        'relationship',
        'isprimary',
    ];

    protected function casts(): array
    {
        return [
            'isprimary' => 'boolean',
        ];
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id');
    }

    public function guardian()
    {
        return $this->belongsTo(Guardian::class, 'parent_id', 'parent_id');
    }
}
