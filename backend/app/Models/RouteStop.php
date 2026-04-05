<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RouteStop extends Model
{
    protected $table = 'routestop';
    protected $primaryKey = 'stop_id';
    public $timestamps = false;

    protected $fillable = ['route_id', 'name', 'stoporder'];

    public function route()
    {
        return $this->belongsTo(BusRoute::class, 'route_id', 'route_id');
    }

    public function studentAssignments()
    {
        return $this->hasMany(StudentBusAssignment::class, 'stop_id', 'stop_id');
    }
}
