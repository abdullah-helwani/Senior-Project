<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ScheduleSlot extends Model
{
    protected $table = 'scheduleslot';
    protected $primaryKey = 'slot_id';
    public $timestamps = false;

    // Note: your table has no end_time column
    protected $fillable = [
        'schedule_id',
        'subject_id',
        'teacher_id',
        'dayofweek',
        'starttime',
    ];

    public const DAY_ORDER = [
        'Monday'    => 1,
        'Tuesday'   => 2,
        'Wednesday' => 3,
        'Thursday'  => 4,
        'Friday'    => 5,
        'Saturday'  => 6,
        'Sunday'    => 7,
    ];

    public function schedule()
    {
        return $this->belongsTo(Schedule::class, 'schedule_id', 'schedule_id');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id', 'id')->with('user');
    }
}
