<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trip extends Model
{
    protected $table = 'trip';
    protected $primaryKey = 'trip_id';
    public $timestamps = false;

    protected $fillable = ['bus_id', 'driver_id', 'route_id', 'date', 'type'];

    protected function casts(): array
    {
        return ['date' => 'date'];
    }

    public function bus()
    {
        return $this->belongsTo(Bus::class, 'bus_id', 'bus_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class, 'driver_id', 'driver_id');
    }

    public function route()
    {
        return $this->belongsTo(BusRoute::class, 'route_id', 'route_id');
    }
}
