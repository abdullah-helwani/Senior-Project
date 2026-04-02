<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceSession extends Model
{
    protected $table = 'attendancesession';
    protected $primaryKey = 'session_id';
    public $timestamps = false;

    protected $fillable = [
        'section_id',
        'date',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
        ];
    }

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id', 'section_id');
    }

    public function attendances()
    {
        return $this->hasMany(StudentAttendance::class, 'session_id', 'session_id');
    }
}
