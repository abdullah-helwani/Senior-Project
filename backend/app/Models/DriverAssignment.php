<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverAssignment extends Model
{
    protected $table = 'driverassignment';
    protected $primaryKey = 'driverassignment_id';
    public $timestamps = false;

    protected $fillable = ['driver_id', 'bus_id'];

    public function driver()
    {
        return $this->belongsTo(Driver::class, 'driver_id', 'driver_id');
    }

    public function bus()
    {
        return $this->belongsTo(Bus::class, 'bus_id', 'bus_id');
    }
}
