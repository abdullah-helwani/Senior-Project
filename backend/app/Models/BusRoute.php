<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Represents a bus route (named BusRoute to avoid clashing with Laravel's Route facade).
 * Maps to the `route` table.
 */
class BusRoute extends Model
{
    protected $table = 'route';
    protected $primaryKey = 'route_id';
    public $timestamps = false;

    protected $fillable = ['name'];

    public function stops()
    {
        return $this->hasMany(RouteStop::class, 'route_id', 'route_id')
                    ->orderBy('stoporder');
    }

    public function studentAssignments()
    {
        return $this->hasMany(StudentBusAssignment::class, 'route_id', 'route_id');
    }
}
