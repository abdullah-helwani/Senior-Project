<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AssessmentResult extends Model
{
    protected $fillable = [
        'assessment_id',
        'student_id',
        'score',
        'grade',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'score'        => 'float',
            'published_at' => 'datetime',
        ];
    }

    public function assessment()
    {
        return $this->belongsTo(Assessment::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class)->with('user');
    }

    /**
     * Auto-calculate letter grade from score percentage.
     */
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
