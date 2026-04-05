<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentBusAssignment extends Model
{
    protected $table = 'studentbusassignment';
    protected $primaryKey = 'sbassignment_id';
    public $timestamps = false;

    protected $fillable = ['student_id', 'bus_id', 'route_id', 'stop_id'];

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id', 'id');
    }

    public function bus()
    {
        return $this->belongsTo(Bus::class, 'bus_id', 'bus_id');
    }

    public function route()
    {
        return $this->belongsTo(BusRoute::class, 'route_id', 'route_id');
    }

    public function stop()
    {
        return $this->belongsTo(RouteStop::class, 'stop_id', 'stop_id');
    }
}
