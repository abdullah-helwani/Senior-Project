<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    protected $table = 'driver';
    protected $primaryKey = 'driver_id';
    public $timestamps = false;

    protected $fillable = ['user_id'];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function assignments()
    {
        return $this->hasMany(DriverAssignment::class, 'driver_id', 'driver_id');
    }

    /**
     * The bus currently assigned to this driver (if any).
     */
    public function currentBus()
    {
        return $this->hasOneThrough(
            Bus::class,
            DriverAssignment::class,
            'driver_id', // FK on driverassignment
            'bus_id',    // FK on bus
            'driver_id', // local key on driver
            'bus_id'     // local key on driverassignment
        );
    }
}
