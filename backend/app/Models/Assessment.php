<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Assessment extends Model
{
    protected $fillable = [
        'subject_id',
        'section_id',
        'title',
        'created_by_user_id',
        'assessment_type',
        'date',
        'max_score',
    ];

    protected function casts(): array
    {
        return [
            'date'      => 'date',
            'max_score' => 'float',
        ];
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function section()
    {
        return $this->belongsTo(Section::class)->with('schoolClass');
    }

    public function createdBy()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function results()
    {
        return $this->hasMany(AssessmentResult::class);
    }
}
