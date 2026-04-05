<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Complaint extends Model
{
    protected $table = 'complaint';
    protected $primaryKey = 'complaint_id';

    protected $fillable = [
        'parent_id',
        'student_id',
        'subject',
        'body',
        'status',
        'admin_reply',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'resolved_at' => 'datetime',
        ];
    }

    public function guardian()
    {
        return $this->belongsTo(Guardian::class, 'parent_id', 'parent_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id');
    }
}
