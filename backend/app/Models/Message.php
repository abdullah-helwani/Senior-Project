<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $fillable = [
        'sender_id',
        'receiver_id',
        'student_id',
        'subject',
        'body',
        'read_at',
    ];

    protected $appends = ['is_read'];

    protected function casts(): array
    {
        return [
            'read_at' => 'datetime',
        ];
    }

    public function getIsReadAttribute(): bool
    {
        return $this->read_at !== null;
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class)->with('user');
    }
}
