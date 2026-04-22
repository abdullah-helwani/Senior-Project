<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AssessmentResult extends Model
{
    protected $table = 'assessmentresult';
    protected $primaryKey = 'result_id';
    public $timestamps = false;

    protected $fillable = [
        'assessment_id',
        'student_id',
        'score',
        'grade',
        'publishedat',
    ];

    protected function casts(): array
    {
        return [
            'score'       => 'float',
            'publishedat' => 'datetime',
        ];
    }

    public function assessment()
    {
        return $this->belongsTo(Assessment::class, 'assessment_id', 'assessment_id');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id', 'id')->with('user');
    }

    public static function calculateGrade(float $score, float $maxScore): string
    {
        $pct = ($maxScore > 0) ? ($score / $maxScore) * 100 : 0;

        return match (true) {
            $pct >= 90 => 'A',
            $pct >= 80 => 'B',
            $pct >= 70 => 'C',
            $pct >= 60 => 'D',
            default    => 'F',
        };
    }
}