<?php

use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Encrypt message contents at rest (paired with the `encrypted` cast on
     * the Message model).
     *
     * 1. Widen `subject` from VARCHAR(255) to TEXT. Laravel's encrypted cast
     *    produces ciphertext far longer than the plaintext, which would
     *    overflow the old 255-char column. (`body` is already TEXT.)
     * 2. Backfill existing plaintext rows into encrypted form so the cast can
     *    decrypt them. Idempotent: rows that already decrypt cleanly are
     *    skipped, so re-running is safe.
     */
    public function up(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->text('subject')->nullable()->change();
        });

        DB::table('messages')
            ->select('id', 'subject', 'body')
            ->orderBy('id')
            ->chunkById(500, function ($rows) {
                foreach ($rows as $row) {
                    $update = [];

                    foreach (['subject', 'body'] as $col) {
                        $value = $row->{$col};

                        if ($value === null || $value === '') {
                            continue;
                        }

                        // Already encrypted? Leave it untouched.
                        try {
                            Crypt::decryptString($value);
                            continue;
                        } catch (DecryptException) {
                            // Plaintext — fall through and encrypt.
                        }

                        $update[$col] = Crypt::encryptString($value);
                    }

                    if ($update) {
                        DB::table('messages')->where('id', $row->id)->update($update);
                    }
                }
            });
    }

    /**
     * Decrypt rows back to plaintext, then restore the narrower column.
     * Decryption runs first so any subject is plaintext before we shrink the
     * column back to VARCHAR(255).
     */
    public function down(): void
    {
        DB::table('messages')
            ->select('id', 'subject', 'body')
            ->orderBy('id')
            ->chunkById(500, function ($rows) {
                foreach ($rows as $row) {
                    $update = [];

                    foreach (['subject', 'body'] as $col) {
                        $value = $row->{$col};

                        if ($value === null || $value === '') {
                            continue;
                        }

                        try {
                            $update[$col] = Crypt::decryptString($value);
                        } catch (DecryptException) {
                            // Already plaintext — skip.
                        }
                    }

                    if ($update) {
                        DB::table('messages')->where('id', $row->id)->update($update);
                    }
                }
            });

        Schema::table('messages', function (Blueprint $table) {
            $table->string('subject')->nullable()->change();
        });
    }
};
