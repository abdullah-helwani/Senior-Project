<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AnalyticsMetric extends Model
{
    protected $table = 'analyticsmetric';
    protected $primaryKey = 'metric_id';
    public $timestamps = false;

    protected $fillable = [
        'report_id',
        'metricname',
        'metricvalue',
        'dimension',
    ];

    public function report()
    {
        return $this->belongsTo(AnalyticsReport::class, 'report_id', 'report_id');
    }
}
