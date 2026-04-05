<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Schedule extends Model
{
    protected $table = 'schedule';
    protected $primaryKey = 'schedule_id';
    public $timestamps = false;

    protected $fillable = ['section_id', 'termname'];

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id', 'section_id')->with('schoolClass');
    }

    public function slots()
    {
        return $this->hasMany(ScheduleSlot::class, 'schedule_id', 'schedule_id');
    }
}
