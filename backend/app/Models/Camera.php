<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Camera extends Model
{
    protected $table = 'camera';
    protected $primaryKey = 'camera_id';
    public $timestamps = false;

    protected $fillable = [
        'location',
        'isactive',
        'code',
        'stream_url',
        'stream_id',
    ];

    protected function casts(): array
    {
        return [
            'isactive' => 'boolean',
        ];
    }

    public function events()
    {
        return $this->hasMany(SurveillanceEvent::class, 'camera_id', 'camera_id');
    }
}
