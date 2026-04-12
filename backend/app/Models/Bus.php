<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Bus extends Model
{
    protected $table = 'bus';
    protected $primaryKey = 'bus_id';
    public $timestamps = false;

    protected $fillable = ['plate_number'];

    public function driverAssignments()
    {
        return $this->hasMany(DriverAssignment::class, 'bus_id', 'bus_id');
    }

    public function studentAssignments()
    {
        return $this->hasMany(StudentBusAssignment::class, 'bus_id', 'bus_id');
    }
}
