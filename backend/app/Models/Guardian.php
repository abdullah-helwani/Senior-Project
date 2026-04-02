<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

// Named Guardian because "Parent" is a reserved word in PHP
class Guardian extends Model
{
    protected $table = 'parents';

    protected $fillable = ['user_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
