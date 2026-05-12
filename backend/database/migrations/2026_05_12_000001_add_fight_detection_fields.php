<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Camera: add KIRA string identifier + stream state
        Schema::table('camera', function (Blueprint $table) {
            $table->string('code', 64)->unique()->nullable()->after('isactive');
            $table->string('stream_url', 512)->nullable()->after('code');
            $table->string('stream_id', 64)->nullable()->after('stream_url');
        });

        // SurveillanceEvent: add confidence, footage path, and review status
        Schema::table('surveillanceevent', function (Blueprint $table) {
            $table->decimal('confidence', 5, 4)->nullable()->after('severity');
            $table->string('footage_path', 512)->nullable()->after('confidence');
            $table->enum('status', ['new', 'acknowledged', 'dismissed'])->default('new')->after('footage_path');
            $table->index(['detectedtype', 'detectedat'], 'surveillanceevent_type_time_idx');
        });
    }

    public function down(): void
    {
        Schema::table('surveillanceevent', function (Blueprint $table) {
            $table->dropIndex('surveillanceevent_type_time_idx');
            $table->dropColumn(['confidence', 'footage_path', 'status']);
        });

        Schema::table('camera', function (Blueprint $table) {
            $table->dropUnique(['code']);
            $table->dropColumn(['code', 'stream_url', 'stream_id']);
        });
    }
};
