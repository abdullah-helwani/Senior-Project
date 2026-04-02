<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentAttendance extends Model
{
    protected $table = 'studentattendance';
    protected $primaryKey = 'attendance_id';
    public $timestamps = false;

    protected $fillable = [
        'session_id',
        'student_id',
        'status',
        'capturedbyuserid',
    ];

    public function session()
    {
        return $this->belongsTo(AttendanceSession::class, 'session_id', 'session_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id');
    }

    public function capturedBy()
    {
        return $this->belongsTo(User::class, 'capturedbyuserid');
    }
}
