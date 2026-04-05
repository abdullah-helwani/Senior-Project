<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Assessment extends Model
{
    protected $table = 'assessment';
    protected $primaryKey = 'assessment_id';

    protected $fillable = [
        'subject_id',
        'section_id',
        'title',
        'createdbyteacherid',
        'assessmenttype',
        'date',
        'maxscore',
    ];

    protected function casts(): array
    {
        return [
            'date'      => 'date',
            'maxscore'  => 'float',
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
