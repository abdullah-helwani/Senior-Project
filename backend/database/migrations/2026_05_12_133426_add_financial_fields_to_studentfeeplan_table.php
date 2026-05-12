<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('studentfeeplan', function (Blueprint $table) {
            $table->decimal('paid_amount', 10, 2)->default(0)->after('balance');
            $table->enum('status', ['unpaid', 'partial', 'paid'])->default('unpaid')->after('paid_amount');
            $table->date('due_date')->nullable()->after('status');
            $table->text('notes')->nullable()->after('due_date');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::table('studentfeeplan', function (Blueprint $table) {
            $table->dropColumn(['paid_amount', 'status', 'due_date', 'notes', 'created_at', 'updated_at']);
        });
    }
};
