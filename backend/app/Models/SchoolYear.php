<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SchoolYear extends Model
{
    protected $table = 'schoolyear';
    protected $primaryKey = 'schoolyearid';

    // Your schoolyear table only has schoolyearid and name
    protected $fillable = ['name'];

    public function classes()
    {
        return $this->hasMany(SchoolClass::class, 'schoolyearid', 'schoolyearid');
    }

    public function feePlans()
    {
        return $this->hasMany(FeePlan::class, 'schoolyear_id', 'schoolyearid');
    }
}
