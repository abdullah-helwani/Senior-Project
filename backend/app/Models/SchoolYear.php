<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SchoolYear extends Model
{
    protected $table = 'schoolyear';
    protected $primaryKey = 'schoolyearid';

    // schoolyear table only has schoolyearid and name — no created_at / updated_at
    public $timestamps = false;

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