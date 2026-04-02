<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

// Named SchoolClass because "Class" is a reserved word in PHP
class SchoolClass extends Model
{
    protected $table = 'school_classes';

    protected $fillable = ['name', 'school_year_id'];

    public function schoolYear()
    {
        return $this->belongsTo(SchoolYear::class);
    }

    public function sections()
    {
        return $this->hasMany(Section::class);
    }
}
