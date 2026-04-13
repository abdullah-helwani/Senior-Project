<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payment', function (Blueprint $table) {
            $table->string('stripe_session_id')->nullable()->after('method');
            $table->string('stripe_payment_intent')->nullable()->after('stripe_session_id');
            $table->string('status')->default('completed')->after('stripe_payment_intent'); // pending, completed, failed
        });
    }

    public function down(): void
    {
        Schema::table('payment', function (Blueprint $table) {
            $table->dropColumn(['stripe_session_id', 'stripe_payment_intent', 'status']);
        });
    }
};
