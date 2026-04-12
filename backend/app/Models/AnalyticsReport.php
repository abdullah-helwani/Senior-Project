<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AnalyticsReport extends Model
{
    protected $table = 'analyticsreport';
    protected $primaryKey = 'report_id';
    public $timestamps = false;

    protected $fillable = [
        'reporttype',
        'periodstart',
        'periodend',
        'generated_at',
        'generatedbyadmin_id',
    ];

    protected function casts(): array
    {
        return [
            'periodstart'  => 'date',
            'periodend'    => 'date',
            'generated_at' => 'datetime',
        ];
    }

    public function generatedByAdmin()
    {
        return $this->belongsTo(Admin::class, 'generatedbyadmin_id', 'admin_id');
    }

    public function metrics()
    {
        return $this->hasMany(AnalyticsMetric::class, 'report_id', 'report_id');
    }
}
