<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'user_name',
        'role',
        'action',
        'endpoint',
        'resource',
        'resource_id',
        'old_values',
        'new_values',
        'ip_address',
        'performed_at',
    ];

    protected function casts(): array
    {
        return [
            'old_values'   => 'array',
            'new_values'   => 'array',
            'performed_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
