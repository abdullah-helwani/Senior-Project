<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationRecipient extends Model
{
    protected $table = 'notificationrecipient';
    protected $primaryKey = 'recipient_id';

    // Your table has no created_at/updated_at
    public $timestamps = false;

    protected $fillable = [
        'notification_id',
        'user_id',
        'status',
        'deliveredat',
        'readat',
    ];

    protected function casts(): array
    {
        return [
            'deliveredat' => 'datetime',
            'readat'      => 'datetime',
        ];
    }

    public function notification()
    {
        return $this->belongsTo(Notification::class, 'notification_id', 'notification_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
