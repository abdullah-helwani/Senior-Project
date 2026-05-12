<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SurveillanceEvent extends Model
{
    protected $table = 'surveillanceevent';
    protected $primaryKey = 'survevent_id';
    public $timestamps = false;

    protected $fillable = [
        'camera_id',
        'detectedtype',
        'detectedat',
        'severity',
        'confidence',
        'footage_path',
        'status',
        'relatedstudent_id',
        'relatedsection_id',
        'relatedassessment_id',
    ];

    protected function casts(): array
    {
        return [
            'detectedat' => 'datetime',
            'confidence' => 'float',
        ];
    }

    public function camera()
    {
        return $this->belongsTo(Camera::class, 'camera_id', 'camera_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'relatedstudent_id', 'id');
    }

    public function section()
    {
        return $this->belongsTo(Section::class, 'relatedsection_id', 'section_id');
    }

    public function assessment()
    {
        return $this->belongsTo(Assessment::class, 'relatedassessment_id', 'assessment_id');
    }
}
