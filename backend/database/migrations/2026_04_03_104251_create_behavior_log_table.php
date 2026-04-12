<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('behaviorlog', function (Blueprint $table) {
            $table->id('log_id');
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->foreignId('teacher_id')->constrained('teachers')->cascadeOnDelete();
            $table->foreignId('section_id')->constrained('section', 'section_id')->cascadeOnDelete();
            $table->enum('type', ['positive', 'negative', 'neutral'])->default('neutral');
            $table->string('title');
            $table->text('description')->nullable();
            $table->date('date');
            $table->boolean('notify_parent')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('behaviorlog');
    }
};
