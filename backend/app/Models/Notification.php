<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $table = 'notification';
    protected $primaryKey = 'notification_id';


    const UPDATED_AT = null;

    protected $fillable = [
        'title',
        'createdbyuserid',
        'channel',
    ];

    public function createdBy()
    {
        return $this->belongsTo(User::class, 'createdbyuserid', 'id');
    }

    public function recipients()
    {
        return $this->hasMany(NotificationRecipient::class, 'notification_id', 'notification_id');
    }
}