<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Rebuilds all schedule slots so no teacher is booked in two sections simultaneously.
 *
 * Root cause: AdditionalDataSeeder used cursor=0 for every section, giving every
 * section the identical (day, time) → subject mapping. Since the same teacher
 * handles a subject across 4 sections, they ended up in 4 classrooms at once.
 *
 * Fix: within each group of 4 sections that share a teacher set, offset the
 * cursor by the section's position (0,1,2,3). Each section still gets every
 * subject the same number of times per week; they just fall on different slots,
 * so the teacher is never double-booked.
 */
class FixScheduleSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Wipe existing slots ──────────────────────
        DB::table('scheduleslot')->delete();

        // ── 2. Collect schedules (one per section) ──────
        $schedules = DB::table('schedule')
            ->join('section', 'section.section_id', '=', 'schedule.section_id')
            ->join('class', 'class.class_id', '=', 'section.class_id')
            ->orderBy('class.name')
            ->orderBy('section.name')
            ->select('schedule.schedule_id', 'schedule.section_id', 'class.name as classname', 'section.name as secname')
            ->get();

        if ($schedules->isEmpty()) {
            $this->command->warn('No schedules found — run AdditionalDataSeeder first.');
            return;
        }

        // ── 3. Subject list (must match seeder order) ───
        $subjects = DB::table('subjects')
            ->whereIn('name', ['Mathematics','Science','English','Arabic','French','Religion','Physics','Chemistry'])
            ->pluck('id', 'name')
            ->toArray();

        $subjList = [
            'Mathematics', 'Science', 'English', 'Arabic',
            'French', 'Religion', 'Physics', 'Chemistry',
        ];
        $subjCount = count($subjList);

        // ── 4. Teacher assignments per (section, subject) ─
        $assignments = DB::table('teacherassignment')
            ->get()
            ->groupBy('section_id');

        // ── 5. Days and periods ─────────────────────────
        $days       = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
        $startTimes = ['08:00', '09:00', '10:00', '11:00', '12:00'];

        // ── 6. Build slots with staggered offsets ───────
        //
        // Sections arrive sorted by grade then A/B:
        //   0=G7A, 1=G7B, 2=G8A, 3=G8B, 4=G9A, 5=G9B, 6=G10A, 7=G10B
        //
        // Teacher groups:  [0-3] share one set of teachers, [4-7] another.
        // Offset within group = index % 4, so A=0, B=1, next-grade-A=2, next-grade-B=3.
        // This guarantees no two sections in the same group share a (day, time, subject).

        $inserted = 0;
        foreach ($schedules as $idx => $sc) {
            $sectionId  = $sc->section_id;
            $scheduleId = $sc->schedule_id;
            $offset     = $idx % 4; // 0,1,2,3 cycling per teacher group

            $sectionAssignments = $assignments->get($sectionId, collect())
                ->keyBy('subject_id');

            $cursor = $offset;
            foreach ($days as $day) {
                foreach ($startTimes as $time) {
                    $subjName = $subjList[$cursor % $subjCount];
                    $subjId   = $subjects[$subjName] ?? null;

                    if ($subjId && $sectionAssignments->has($subjId)) {
                        $teacherId = $sectionAssignments->get($subjId)->teacher_id;

                        DB::table('scheduleslot')->insert([
                            'schedule_id' => $scheduleId,
                            'subject_id'  => $subjId,
                            'teacher_id'  => $teacherId,
                            'dayofweek'   => $day,
                            'starttime'   => $time,
                        ]);
                        $inserted++;
                    }

                    $cursor++;
                }
            }
        }

        $this->command->info("FixScheduleSeeder: rebuilt {$inserted} schedule slots for {$schedules->count()} sections.");

        // ── 7. Verify: count remaining conflicts ─────────
        $conflicts = DB::select("
            SELECT COUNT(*) AS cnt
            FROM scheduleslot ss1
            JOIN scheduleslot ss2
              ON  ss2.teacher_id  = ss1.teacher_id
              AND ss2.dayofweek   = ss1.dayofweek
              AND ss2.starttime   = ss1.starttime
              AND ss2.slot_id     > ss1.slot_id
            JOIN schedule sc1 ON sc1.schedule_id = ss1.schedule_id
            JOIN schedule sc2 ON sc2.schedule_id = ss2.schedule_id
            WHERE sc1.section_id <> sc2.section_id
        ");
        $remaining = $conflicts[0]->cnt ?? '?';
        $this->command->info("Teacher double-bookings remaining: {$remaining} (should be 0).");
    }
}
