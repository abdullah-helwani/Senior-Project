<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SchoolClass extends Model
{
    protected $table = 'class';
    protected $primaryKey = 'class_id';

    public $timestamps = false;  

    protected $fillable = ['name', 'schoolyearid'];

    public function schoolYear()
    {
        return $this->belongsTo(SchoolYear::class, 'schoolyearid', 'schoolyearid');
    }

    public function sections()
    {
        return $this->hasMany(Section::class, 'class_id', 'class_id');
    }
}