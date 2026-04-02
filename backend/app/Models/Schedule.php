<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Schedule extends Model
{
    protected $fillable = ['section_id', 'term_name'];

    public function section()
    {
        return $this->belongsTo(Section::class)->with('schoolClass');
    }

    public function slots()
    {
        return $this->hasMany(ScheduleSlot::class);
    }
}
