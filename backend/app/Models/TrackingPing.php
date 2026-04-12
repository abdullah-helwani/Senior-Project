<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrackingPing extends Model
{
    protected $table = 'trackingping';
    protected $primaryKey = 'ping_id';
    public $timestamps = false;

    protected $fillable = ['trip_id', 'latitude', 'longitude', 'capturedat'];

    protected function casts(): array
    {
        return [
            'latitude'   => 'float',
            'longitude'  => 'float',
            'capturedat' => 'datetime',
        ];
    }

    public function trip()
    {
        return $this->belongsTo(Trip::class, 'trip_id', 'trip_id');
    }
}
