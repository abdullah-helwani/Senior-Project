<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

/**
 * Additive seeder — does NOT wipe any existing data.
 * Run with:  php artisan db:seed --class=AdditionalDataSeeder
 *
 * Targets:
 *   8 subjects, 16 teachers (2 per subject),
 *   4 grades x 2 sections (= 8 sections), 96 students (12 per section),
 *   70 parents (some with 2-3 kids), 6 buses / 6 drivers / 6 routes,
 *   ~192 homeworks (3 per subject per section) with mixed submissions.
 *
 * All passwords: password123
 */
class AdditionalDataSeeder extends Seeder
{
    public function run(): void
    {
        $now = Carbon::now();
        $password = Hash::make('password123');
        mt_srand(42);

        $upsertUser = function (array $row) use ($now) {
            $existing = DB::table('users')->where('email', $row['email'])->value('id');
            if ($existing) return $existing;
            return DB::table('users')->insertGetId(array_merge($row, [
                'created_at' => $now, 'updated_at' => $now,
            ]));
        };

        // ── 1. SCHOOL YEAR ──────────────────────────────
        $schoolYearId = DB::table('schoolyear')->where('name', '2025-2026')->value('schoolyearid')
            ?: DB::table('schoolyear')->insertGetId(['name' => '2025-2026'], 'schoolyearid');

        // ── 2. SUBJECTS ─────────────────────────────────
        $subjectsTarget = [
            'Mathematics' => 'MATH101',
            'Science'     => 'SCI101',
            'English'     => 'ENG101',
            'Arabic'      => 'ARA101',
            'French'      => 'FRE101',
            'Religion'    => 'REL101',
            'Physics'     => 'PHY101',
            'Chemistry'   => 'CHE101',
        ];
        $subjectIds = [];
        foreach ($subjectsTarget as $name => $code) {
            $subjectIds[$name] = DB::table('subjects')->where('name', $name)->value('id')
                ?: DB::table('subjects')->insertGetId([
                    'name' => $name, 'code' => $code,
                    'created_at' => $now, 'updated_at' => $now,
                ]);
        }

        // ── 3. CLASSES + SECTIONS (Grades 7-10, A & B) ──
        $sections = [];
        $sectionList = [];
        foreach ([7, 8, 9, 10] as $grade) {
            $className = "Grade {$grade}";
            $classId = DB::table('class')
                ->where('name', $className)->where('schoolyearid', $schoolYearId)
                ->value('class_id')
                ?: DB::table('class')->insertGetId([
                    'name' => $className, 'schoolyearid' => $schoolYearId,
                ], 'class_id');

            foreach (['A', 'B'] as $sec) {
                $secName = "Section {$sec}";
                $secId = DB::table('section')
                    ->where('class_id', $classId)->where('name', $secName)
                    ->value('section_id')
                    ?: DB::table('section')->insertGetId([
                        'class_id' => $classId, 'name' => $secName,
                    ], 'section_id');
                $sections[$grade][$sec] = $secId;
                $sectionList[] = ['section_id' => $secId, 'grade' => $grade, 'sec' => $sec];
            }
        }

        // ── 4. TEACHERS (2 per subject = 16) ────────────
        $teacherSlots = [
            ['email' => 'sara@school.test',               'name' => 'Sara Ahmed',          'gender' => 'female', 'subject' => 'Mathematics'],
            ['email' => 'teacher.math2@school.test',      'name' => 'Hala Al-Otaibi',      'gender' => 'female', 'subject' => 'Mathematics'],
            ['email' => 'omar@school.test',               'name' => 'Omar Hassan',         'gender' => 'male',   'subject' => 'English'],
            ['email' => 'teacher.english2@school.test',   'name' => 'Layla Al-Harbi',      'gender' => 'female', 'subject' => 'English'],
            ['email' => 'teacher.arabic1@school.test',    'name' => 'Mansour Al-Qahtani',  'gender' => 'male',   'subject' => 'Arabic'],
            ['email' => 'teacher.arabic2@school.test',    'name' => 'Najla Al-Saud',       'gender' => 'female', 'subject' => 'Arabic'],
            ['email' => 'teacher.science1@school.test',   'name' => 'Yusuf Al-Shehri',     'gender' => 'male',   'subject' => 'Science'],
            ['email' => 'teacher.science2@school.test',   'name' => 'Reem Al-Mutairi',     'gender' => 'female', 'subject' => 'Science'],
            ['email' => 'teacher.french1@school.test',    'name' => 'Karim Al-Ghamdi',     'gender' => 'male',   'subject' => 'French'],
            ['email' => 'teacher.french2@school.test',    'name' => 'Nour Al-Anazi',       'gender' => 'female', 'subject' => 'French'],
            ['email' => 'teacher.religion1@school.test',  'name' => 'Abdullah Al-Dossari', 'gender' => 'male',   'subject' => 'Religion'],
            ['email' => 'teacher.religion2@school.test',  'name' => 'Maryam Al-Zahrani',   'gender' => 'female', 'subject' => 'Religion'],
            ['email' => 'teacher.physics1@school.test',   'name' => 'Faisal Al-Subaie',    'gender' => 'male',   'subject' => 'Physics'],
            ['email' => 'teacher.physics2@school.test',   'name' => 'Hanan Al-Ahmadi',     'gender' => 'female', 'subject' => 'Physics'],
            ['email' => 'teacher.chemistry1@school.test', 'name' => 'Khalid Al-Mansour',   'gender' => 'male',   'subject' => 'Chemistry'],
            ['email' => 'teacher.chemistry2@school.test', 'name' => 'Amal Al-Rashidi',     'gender' => 'female', 'subject' => 'Chemistry'],
        ];
        $teacherIdsBySubject = [];
        foreach ($teacherSlots as $idx => $slot) {
            $userId = $upsertUser([
                'name' => $slot['name'], 'email' => $slot['email'],
                'phone' => '050' . str_pad((string)(2000000 + $idx), 7, '0', STR_PAD_LEFT),
                'password' => $password, 'role_type' => 'teacher', 'is_active' => true,
            ]);
            $teacherId = DB::table('teachers')->where('user_id', $userId)->value('id')
                ?: DB::table('teachers')->insertGetId([
                    'user_id' => $userId,
                    'date_of_birth' => Carbon::create(1985 + ($idx % 10), ($idx % 12) + 1, ($idx % 27) + 1)->toDateString(),
                    'gender' => $slot['gender'],
                    'address' => ($idx + 1) . ' Teacher Street',
                    'hire_date' => Carbon::create(2018 + ($idx % 6), 9, 1)->toDateString(),
                    'status' => 'active',
                    'created_at' => $now, 'updated_at' => $now,
                ]);
            $teacherIdsBySubject[$slot['subject']][] = $teacherId;
        }

        // ── 5. TEACHER ASSIGNMENTS (each subject: T1 -> first 4 sections, T2 -> last 4) ─
        $sectionAssignments = [];
        foreach ($subjectIds as $subjName => $subjId) {
            $tList = $teacherIdsBySubject[$subjName];
            $half = (int) ceil(count($sectionList) / 2);
            foreach ($sectionList as $i => $sec) {
                $teacherId = $i < $half ? $tList[0] : ($tList[1] ?? $tList[0]);
                $exists = DB::table('teacherassignment')
                    ->where('teacher_id', $teacherId)
                    ->where('section_id', $sec['section_id'])
                    ->where('subject_id', $subjId)->exists();
                if (!$exists) {
                    DB::table('teacherassignment')->insert([
                        'teacher_id' => $teacherId,
                        'section_id' => $sec['section_id'],
                        'subject_id' => $subjId,
                    ]);
                }
                $sectionAssignments[$sec['section_id']][$subjName] = $teacherId;
            }
        }

        // ── 6. PARENTS (70: 1 existing + 69 new) ────────
        $maleFirst = ['Ali','Mohammed','Omar','Khalid','Ahmed','Yusuf','Ibrahim','Hassan','Hussein','Abdullah','Fahad','Saud','Bandar','Faisal','Salman','Nawaf','Tariq','Walid','Majed','Sami','Nasser','Rashid','Hamad','Mansour','Ziad','Karim','Adel','Marwan','Bilal','Anas','Saif','Hamza','Yazid','Talal','Othman','Jamal','Issam','Nabil','Rami','Mazen'];
        $femaleFirst = ['Fatima','Aisha','Maryam','Zainab','Khadija','Sara','Layla','Hala','Reem','Nour','Salma','Hanan','Amal','Lina','Dana','Rana','Hind','Mona','Najla','Yasmin','Lujain','Shahad','Rawan','Maha','Areej','Latifa','Aida','Munira','Nawal','Sumaya','Dalal','Hessa','Ghada','Asma','Bushra','Tala'];
        $lastNames = ['Al-Saud','Al-Otaibi','Al-Qahtani','Al-Ghamdi','Al-Shehri','Al-Harbi','Al-Mutairi','Al-Dossari','Al-Zahrani','Al-Ahmadi','Al-Rashidi','Al-Anazi','Al-Subaie','Al-Fahad','Al-Mansour','Al-Khalifa','Al-Hashimi','Al-Rasheed','Al-Hamdan','Al-Sulaiman'];

        $parentIds = [];
        $mainParentUserId = $upsertUser([
            'name' => 'Mohammed Ali', 'email' => 'parent@school.test',
            'phone' => '0504444444', 'password' => $password,
            'role_type' => 'parent', 'is_active' => true,
        ]);
        $mainParentId = DB::table('parent')->where('user_id', $mainParentUserId)->value('parent_id')
            ?: DB::table('parent')->insertGetId(['user_id' => $mainParentUserId], 'parent_id');
        $parentIds[] = $mainParentId;

        for ($i = 1; $i <= 69; $i++) {
            $male = ($i % 2 === 0);
            $first = $male ? $maleFirst[$i % count($maleFirst)] : $femaleFirst[$i % count($femaleFirst)];
            $last = $lastNames[$i % count($lastNames)];
            $userId = $upsertUser([
                'name' => "{$first} {$last}",
                'email' => "parent{$i}@school.test",
                'phone' => '050' . str_pad((string)(4000000 + $i), 7, '0', STR_PAD_LEFT),
                'password' => $password, 'role_type' => 'parent', 'is_active' => true,
            ]);
            $pid = DB::table('parent')->where('user_id', $userId)->value('parent_id')
                ?: DB::table('parent')->insertGetId(['user_id' => $userId], 'parent_id');
            $parentIds[] = $pid;
        }

        // ── 7. STUDENTS (96 total — Ali & Fatima already in 10A) ─
        $studentRows = [];
        $upsertStudent = function ($email, $name, $gender, $sectionId, $grade, $birthYear, $idx)
            use ($upsertUser, $now, $password, &$studentRows)
        {
            $userId = $upsertUser([
                'name' => $name, 'email' => $email,
                'phone' => '050' . str_pad((string)(3000000 + $idx), 7, '0', STR_PAD_LEFT),
                'password' => $password, 'role_type' => 'student', 'is_active' => true,
            ]);
            $studentId = DB::table('students')->where('user_id', $userId)->value('id')
                ?: DB::table('students')->insertGetId([
                    'user_id' => $userId,
                    'date_of_birth' => Carbon::create($birthYear, (($idx*7) % 12) + 1, (($idx*11) % 27) + 1)->toDateString(),
                    'gender' => $gender,
                    'address' => ($idx + 1) . ' Student Avenue',
                    'enrollment_date' => '2025-09-01',
                    'graduation_year' => 2026 + (12 - $grade),
                    'status' => 'active',
                    'created_at' => $now, 'updated_at' => $now,
                ]);
            $studentRows[] = [
                'student_id' => $studentId, 'gender' => $gender,
                'section_id' => $sectionId, 'grade' => $grade,
            ];
        };

        $sIdx = 0;
        $upsertStudent('ali@school.test',    'Ali Mohammed',  'male',   $sections[10]['A'], 10, 2011, $sIdx++);
        $upsertStudent('fatima@school.test', 'Fatima Khalid', 'female', $sections[10]['A'], 10, 2011, $sIdx++);

        foreach ([7, 8, 9, 10] as $grade) {
            $birthYear = 2026 - 5 - $grade; // 7→2014, 8→2013, 9→2012, 10→2011
            foreach (['A', 'B'] as $sec) {
                $sectionId = $sections[$grade][$sec];
                $inSection = count(array_filter($studentRows, fn($s) => $s['section_id'] === $sectionId));
                while ($inSection < 12) {
                    $male = ($sIdx % 2 === 0);
                    $first = $male ? $maleFirst[$sIdx % count($maleFirst)] : $femaleFirst[$sIdx % count($femaleFirst)];
                    $last = $lastNames[$sIdx % count($lastNames)];
                    $email = 'student' . str_pad((string)$sIdx, 3, '0', STR_PAD_LEFT) . '@school.test';
                    $upsertStudent($email, "{$first} {$last}", $male ? 'male' : 'female',
                                   $sectionId, $grade, $birthYear, $sIdx);
                    $sIdx++;
                    $inSection++;
                }
            }
        }

        // ── 8. ENROLLMENTS ──────────────────────────────
        foreach ($studentRows as $s) {
            $exists = DB::table('enrollment')
                ->where('student_id', $s['student_id'])
                ->where('section_id', $s['section_id'])->exists();
            if (!$exists) {
                DB::table('enrollment')->insert([
                    'student_id' => $s['student_id'],
                    'section_id' => $s['section_id'],
                    'status' => 'active',
                ]);
            }
        }

        // ── 9. STUDENT-PARENT LINKS ─────────────────────
        // Ali + Fatima → mainParent. Others split across parents 2..70 (some get 2-3 kids).
        $aliId = $studentRows[0]['student_id'];
        $fatimaId = $studentRows[1]['student_id'];
        foreach ([$aliId, $fatimaId] as $sid) {
            $exists = DB::table('studentguardian')
                ->where('student_id', $sid)->where('parent_id', $mainParentId)->exists();
            if (!$exists) {
                DB::table('studentguardian')->insert([
                    'student_id' => $sid, 'parent_id' => $mainParentId,
                    'relationship' => 'father', 'isprimary' => true,
                ]);
            }
        }

        $remaining = array_slice($studentRows, 2);
        $pool = array_slice($parentIds, 1); // 69 parents
        foreach ($remaining as $i => $s) {
            $pIdx = $i < count($pool) ? $i : (($i - count($pool)) % count($pool));
            $pid = $pool[$pIdx];
            $exists = DB::table('studentguardian')
                ->where('student_id', $s['student_id'])->where('parent_id', $pid)->exists();
            if (!$exists) {
                DB::table('studentguardian')->insert([
                    'student_id' => $s['student_id'], 'parent_id' => $pid,
                    'relationship' => 'father', 'isprimary' => true,
                ]);
            }
        }

        // ── 10. SCHEDULE + SLOTS (5 days x 5 periods) ──
        $days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
        $startTimes = ['08:00', '09:00', '10:00', '11:00', '12:00'];
        $subjList = array_keys($subjectIds);
        foreach ($sectionList as $sec) {
            $scheduleId = DB::table('schedule')->where('section_id', $sec['section_id'])->value('schedule_id')
                ?: DB::table('schedule')->insertGetId([
                    'section_id' => $sec['section_id'], 'termname' => 'Term 1',
                ], 'schedule_id');

            $cursor = 0;
            foreach ($days as $day) {
                foreach ($startTimes as $time) {
                    $subj = $subjList[$cursor % count($subjList)];
                    $teacherId = $sectionAssignments[$sec['section_id']][$subj];
                    $exists = DB::table('scheduleslot')
                        ->where('schedule_id', $scheduleId)
                        ->where('dayofweek', $day)
                        ->where('starttime', $time)->exists();
                    if (!$exists) {
                        DB::table('scheduleslot')->insert([
                            'schedule_id' => $scheduleId,
                            'subject_id' => $subjectIds[$subj],
                            'teacher_id' => $teacherId,
                            'dayofweek' => $day,
                            'starttime' => $time,
                        ]);
                    }
                    $cursor++;
                }
            }
        }

        // ── 11. HOMEWORK (3 per subject per section) ────
        $hwTitles = [
            'Arabic'      => ['Arabic Reading Comprehension', 'Arabic Grammar Worksheet', 'Arabic Poetry Analysis'],
            'English'     => ['English Vocabulary List', 'English Essay Draft', 'English Grammar Exercises'],
            'Mathematics' => ['Algebra Practice', 'Math Word Problems', 'Geometry Set'],
            'Science'     => ['Science Lab Report', 'Science Chapter Review', 'Science Diagram Labeling'],
            'French'      => ['French Conjugation Drill', 'French Translation Exercise', 'French Dialogue Writing'],
            'Religion'    => ['Religion Memorization Task', 'Religion Reflection Essay', 'Religion Quiz Prep'],
            'Physics'     => ['Physics Problem Set', 'Physics Lab Calculations', 'Physics Concept Review'],
            'Chemistry'   => ['Chemistry Equations Practice', 'Periodic Table Quiz', 'Chemistry Lab Write-up'],
        ];
        $offsetCycle = [-10, -5, -2, 1, 5, 10, 14];
        $homeworkInserted = [];
        $hwCounter = 0;
        foreach ($sectionList as $sec) {
            foreach ($subjectIds as $subjName => $subjId) {
                $teacherId = $sectionAssignments[$sec['section_id']][$subjName];
                foreach ($hwTitles[$subjName] as $title) {
                    $offset = $offsetCycle[$hwCounter % count($offsetCycle)];
                    $dueDate = Carbon::now()->addDays($offset)->toDateString();
                    $existing = DB::table('homework')
                        ->where('section_id', $sec['section_id'])
                        ->where('subject_id', $subjId)
                        ->where('title', $title)->value('id');
                    if ($existing) {
                        $homeworkInserted[] = ['id' => $existing, 'section_id' => $sec['section_id'], 'due_date' => $dueDate];
                    } else {
                        $id = DB::table('homework')->insertGetId([
                            'subject_id' => $subjId,
                            'teacher_id' => $teacherId,
                            'section_id' => $sec['section_id'],
                            'title' => $title,
                            'description' => "Complete the {$title} for {$subjName}.",
                            'due_date' => $dueDate,
                            'created_at' => $now, 'updated_at' => $now,
                        ]);
                        $homeworkInserted[] = ['id' => $id, 'section_id' => $sec['section_id'], 'due_date' => $dueDate];
                    }
                    $hwCounter++;
                }
            }
        }

        // ── 11b. HOMEWORK SUBMISSIONS (~50% coverage) ───
        $studentsBySection = [];
        foreach ($studentRows as $s) {
            $studentsBySection[$s['section_id']][] = $s['student_id'];
        }
        $batch = [];
        foreach ($homeworkInserted as $hw) {
            $isPast = Carbon::parse($hw['due_date'])->isPast();
            foreach ($studentsBySection[$hw['section_id']] ?? [] as $studentId) {
                if (mt_rand(0, 100) > ($isPast ? 70 : 40)) continue;
                $exists = DB::table('homeworksubmission')
                    ->where('homework_id', $hw['id'])
                    ->where('student_id', $studentId)->exists();
                if ($exists) continue;
                $status = $isPast ? (mt_rand(0, 100) < 60 ? 'graded' : 'submitted') : 'submitted';
                $score = $status === 'graded' ? mt_rand(60, 100) : null;
                $batch[] = [
                    'homework_id' => $hw['id'],
                    'student_id'  => $studentId,
                    'submittedat' => Carbon::parse($hw['due_date'])->subDays(mt_rand(0, 2)),
                    'score'       => $score,
                    'status'      => $status,
                ];
                if (count($batch) >= 500) {
                    DB::table('homeworksubmission')->insert($batch);
                    $batch = [];
                }
            }
        }
        if ($batch) DB::table('homeworksubmission')->insert($batch);

        // ── 12. BUSES + DRIVERS + ROUTES (6 each) ───────
        $busDef = [
            ['email' => 'driver@school.test',  'name' => 'Khalid Mansour',     'plate' => 'SBQ-4231', 'route' => 'Route A – North District',
             'stops' => ['Al-Noor Mosque','Central Market','Al-Wafa Plaza','Olaya Junction','School Main Gate']],
            ['email' => 'driver2@school.test', 'name' => 'Saud Al-Otaibi',     'plate' => 'SBQ-5142', 'route' => 'Route B – South District',
             'stops' => ['Al-Salam Square','City Park','Al-Andalus Roundabout','South Gate Mall','Library Stop','School Main Gate']],
            ['email' => 'driver3@school.test', 'name' => 'Bandar Al-Harbi',    'plate' => 'SBQ-6253', 'route' => 'Route C – East District',
             'stops' => ['Al-Shifa Hospital','East Tower','Al-Yasmin Garden','Sunrise Mall','School Main Gate']],
            ['email' => 'driver4@school.test', 'name' => 'Nawaf Al-Subaie',    'plate' => 'SBQ-7364', 'route' => 'Route D – West District',
             'stops' => ['Al-Fanar Tower','West Park','Al-Manar Junction','Westside Plaza','Sports Complex','School Main Gate']],
            ['email' => 'driver5@school.test', 'name' => 'Fahad Al-Ghamdi',    'plate' => 'SBQ-8475', 'route' => 'Route E – Central',
             'stops' => ['Central Square','Heritage Museum','Old Town','Al-Khaleej Junction','School Main Gate']],
            ['email' => 'driver6@school.test', 'name' => 'Tariq Al-Dossari',   'plate' => 'SBQ-9586', 'route' => 'Route F – Coastal',
             'stops' => ['Coastal Road Stop','Marina Plaza','Beach Junction','Pearl Tower','Seaside Park','School Main Gate']],
        ];
        $busInfo = [];
        foreach ($busDef as $b => $def) {
            $userId = $upsertUser([
                'name' => $def['name'], 'email' => $def['email'],
                'phone' => '050' . str_pad((string)(5000000 + $b), 7, '0', STR_PAD_LEFT),
                'password' => $password, 'role_type' => 'driver', 'is_active' => true,
            ]);
            $driverId = DB::table('driver')->where('user_id', $userId)->value('driver_id')
                ?: DB::table('driver')->insertGetId(['user_id' => $userId], 'driver_id');

            $busId = DB::table('bus')->where('plate_number', $def['plate'])->value('bus_id')
                ?: DB::table('bus')->insertGetId(['plate_number' => $def['plate']], 'bus_id');

            $hasAssign = DB::table('driverassignment')
                ->where('driver_id', $driverId)->where('bus_id', $busId)->exists();
            if (!$hasAssign) {
                DB::table('driverassignment')->insert(['driver_id' => $driverId, 'bus_id' => $busId]);
            }

            $routeId = DB::table('route')->where('name', $def['route'])->value('route_id')
                ?: DB::table('route')->insertGetId(['name' => $def['route']], 'route_id');

            $stopIds = [];
            foreach ($def['stops'] as $i => $stopName) {
                $stopId = DB::table('routestop')
                    ->where('route_id', $routeId)->where('name', $stopName)
                    ->value('stop_id')
                    ?: DB::table('routestop')->insertGetId([
                        'route_id' => $routeId,
                        'name' => $stopName,
                        'stoporder' => $i + 1,
                    ], 'stop_id');
                $stopIds[] = $stopId;
            }
            $busInfo[] = ['bus_id' => $busId, 'driver_id' => $driverId,
                          'route_id' => $routeId, 'stop_ids' => $stopIds];
        }

        // ── 13. STUDENT-BUS ASSIGNMENT (16 per bus) ─────
        foreach ($studentRows as $idx => $s) {
            $bIdx = min(intdiv($idx, 16), 5);
            $bus = $busInfo[$bIdx];
            $boardingStops = array_slice($bus['stop_ids'], 0, count($bus['stop_ids']) - 1);
            $stopId = $boardingStops[$idx % count($boardingStops)];
            $exists = DB::table('studentbusassignment')
                ->where('student_id', $s['student_id'])->exists();
            if (!$exists) {
                DB::table('studentbusassignment')->insert([
                    'student_id' => $s['student_id'],
                    'bus_id'     => $bus['bus_id'],
                    'route_id'   => $bus['route_id'],
                    'stop_id'    => $stopId,
                ]);
            }
        }

        $this->command->info('=== Additional data seeded (additive — nothing wiped) ===');
        $this->command->info('Subjects: ' . count($subjectIds));
        $this->command->info('Teachers: ' . count($teacherSlots) . ' (2 per subject)');
        $this->command->info('Sections: ' . count($sectionList));
        $this->command->info('Students: ' . count($studentRows));
        $this->command->info('Parents:  ' . count($parentIds));
        $this->command->info('Buses/Drivers/Routes: ' . count($busInfo));
        $this->command->info('Homework rows: ' . count($homeworkInserted));
        $this->command->info('All passwords: password123');
    }
}
