<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TeacherAvailability extends Model
{
    protected $table = 'teacheravailability';
    protected $primaryKey = 'availability_id';
    public $timestamps = false;

    protected $fillable = [
        'teacher_id',
        'dayofweek',
        'start_time',
        'end_time',
        'availabilitytype',
    ];

    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id', 'id');
    }
}
