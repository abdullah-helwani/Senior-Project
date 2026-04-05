<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TripStopEvent extends Model
{
    protected $table = 'tripstopevent';
    protected $primaryKey = 'trpstopevent_id';
    public $timestamps = false;

    protected $fillable = ['trip_id', 'stop_id', 'student_id', 'eventtype', 'eventat'];

    protected function casts(): array
    {
        return ['eventat' => 'datetime'];
    }

    public function trip()
    {
        return $this->belongsTo(Trip::class, 'trip_id', 'trip_id');
    }

    public function stop()
    {
        return $this->belongsTo(RouteStop::class, 'stop_id', 'stop_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id', 'id');
    }
}
