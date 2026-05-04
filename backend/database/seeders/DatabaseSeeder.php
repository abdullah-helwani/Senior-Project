<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * All passwords are: password123
     */
    public function run(): void
    {
        $now = Carbon::now();
        $password = Hash::make('password123');

        // ─────────────────────────────────────────────
        // 1. USERS
        // ─────────────────────────────────────────────
        $adminUserId = DB::table('users')->insertGetId([
            'name' => 'Admin User', 'email' => 'admin@school.test',
            'phone' => '0501111111', 'password' => $password,
            'role_type' => 'admin', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $teacherUserId = DB::table('users')->insertGetId([
            'name' => 'Sara Ahmed', 'email' => 'sara@school.test',
            'phone' => '0502222222', 'password' => $password,
            'role_type' => 'teacher', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $teacher2UserId = DB::table('users')->insertGetId([
            'name' => 'Omar Hassan', 'email' => 'omar@school.test',
            'phone' => '0502222233', 'password' => $password,
            'role_type' => 'teacher', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $student1UserId = DB::table('users')->insertGetId([
            'name' => 'Ali Mohammed', 'email' => 'ali@school.test',
            'phone' => '0503333333', 'password' => $password,
            'role_type' => 'student', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $student2UserId = DB::table('users')->insertGetId([
            'name' => 'Fatima Khalid', 'email' => 'fatima@school.test',
            'phone' => '0503333344', 'password' => $password,
            'role_type' => 'student', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $parentUserId = DB::table('users')->insertGetId([
            'name' => 'Mohammed Ali', 'email' => 'parent@school.test',
            'phone' => '0504444444', 'password' => $password,
            'role_type' => 'parent', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        // ─────────────────────────────────────────────
        // 2. ROLE PROFILES
        // ─────────────────────────────────────────────
        DB::table('admin')->insertGetId(['user_id' => $adminUserId], 'admin_id');

        $teacherId = DB::table('teachers')->insertGetId([
            'user_id' => $teacherUserId, 'date_of_birth' => '1985-03-15',
            'gender' => 'female', 'address' => '123 Main St',
            'hire_date' => '2020-09-01', 'status' => 'active',
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $teacher2Id = DB::table('teachers')->insertGetId([
            'user_id' => $teacher2UserId, 'date_of_birth' => '1990-07-20',
            'gender' => 'male', 'address' => '456 Oak Ave',
            'hire_date' => '2021-09-01', 'status' => 'active',
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $student1Id = DB::table('students')->insertGetId([
            'user_id' => $student1UserId, 'date_of_birth' => '2010-05-10',
            'gender' => 'male', 'address' => '789 Elm St',
            'enrollment_date' => '2024-09-01', 'graduation_year' => 2028,
            'status' => 'active', 'created_at' => $now, 'updated_at' => $now,
        ]);

        $student2Id = DB::table('students')->insertGetId([
            'user_id' => $student2UserId, 'date_of_birth' => '2010-08-22',
            'gender' => 'female', 'address' => '321 Pine Rd',
            'enrollment_date' => '2024-09-01', 'graduation_year' => 2028,
            'status' => 'active', 'created_at' => $now, 'updated_at' => $now,
        ]);

        $parentId = DB::table('parent')->insertGetId([
            'user_id' => $parentUserId,
        ], 'parent_id');

        // Link parent to both students
        DB::table('studentguardian')->insert([
            ['student_id' => $student1Id, 'parent_id' => $parentId, 'relationship' => 'father', 'isprimary' => true],
            ['student_id' => $student2Id, 'parent_id' => $parentId, 'relationship' => 'father', 'isprimary' => true],
        ]);

        // ─────────────────────────────────────────────
        // 3. SCHOOL STRUCTURE
        // ─────────────────────────────────────────────
        $schoolYearId = DB::table('schoolyear')->insertGetId([
            'name' => '2025-2026',
        ], 'schoolyearid');

        $classId = DB::table('class')->insertGetId([
            'name' => 'Grade 10', 'schoolyearid' => $schoolYearId,
        ], 'class_id');

        $sectionId = DB::table('section')->insertGetId([
            'class_id' => $classId, 'name' => 'Section A',
        ], 'section_id');

        // ─────────────────────────────────────────────
        // 4. SUBJECTS
        // ─────────────────────────────────────────────
        $mathId = DB::table('subjects')->insertGetId([
            'name' => 'Mathematics', 'code' => 'MATH101',
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $scienceId = DB::table('subjects')->insertGetId([
            'name' => 'Science', 'code' => 'SCI101',
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $englishId = DB::table('subjects')->insertGetId([
            'name' => 'English', 'code' => 'ENG101',
            'created_at' => $now, 'updated_at' => $now,
        ]);

        // ─────────────────────────────────────────────
        // 5. TEACHER ASSIGNMENTS
        // ─────────────────────────────────────────────
        DB::table('teacherassignment')->insert([
            ['teacher_id' => $teacherId, 'section_id' => $sectionId, 'subject_id' => $mathId],
            ['teacher_id' => $teacherId, 'section_id' => $sectionId, 'subject_id' => $scienceId],
            ['teacher_id' => $teacher2Id, 'section_id' => $sectionId, 'subject_id' => $englishId],
        ]);

        // ─────────────────────────────────────────────
        // 6. ENROLLMENTS
        // ─────────────────────────────────────────────
        DB::table('enrollment')->insert([
            ['student_id' => $student1Id, 'section_id' => $sectionId, 'status' => 'active'],
            ['student_id' => $student2Id, 'section_id' => $sectionId, 'status' => 'active'],
        ]);

        // ─────────────────────────────────────────────
        // 7. SCHEDULE (weekly timetable)
        // ─────────────────────────────────────────────
        $scheduleId = DB::table('schedule')->insertGetId([
            'section_id' => $sectionId, 'termname' => 'Term 1',
        ], 'schedule_id');

        DB::table('scheduleslot')->insert([
            ['schedule_id' => $scheduleId, 'subject_id' => $mathId, 'teacher_id' => $teacherId, 'dayofweek' => 'Sunday', 'starttime' => '08:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $scienceId, 'teacher_id' => $teacherId, 'dayofweek' => 'Sunday', 'starttime' => '09:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $englishId, 'teacher_id' => $teacher2Id, 'dayofweek' => 'Sunday', 'starttime' => '10:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $mathId, 'teacher_id' => $teacherId, 'dayofweek' => 'Monday', 'starttime' => '08:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $englishId, 'teacher_id' => $teacher2Id, 'dayofweek' => 'Monday', 'starttime' => '09:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $scienceId, 'teacher_id' => $teacherId, 'dayofweek' => 'Tuesday', 'starttime' => '08:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $mathId, 'teacher_id' => $teacherId, 'dayofweek' => 'Tuesday', 'starttime' => '09:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $englishId, 'teacher_id' => $teacher2Id, 'dayofweek' => 'Wednesday', 'starttime' => '08:00'],
            ['schedule_id' => $scheduleId, 'subject_id' => $scienceId, 'teacher_id' => $teacherId, 'dayofweek' => 'Wednesday', 'starttime' => '09:00'],
        ]);

        // ─────────────────────────────────────────────
        // 8. ASSESSMENTS + RESULTS
        // ─────────────────────────────────────────────
        $mathExamId = DB::table('assessment')->insertGetId([
            'subject_id' => $mathId, 'section_id' => $sectionId,
            'title' => 'Math Midterm Exam', 'createdbyteacherid' => $teacherId,
            'assessmenttype' => 'exam', 'date' => '2025-11-15', 'maxscore' => 100,
        ], 'assessment_id');

        $mathQuizId = DB::table('assessment')->insertGetId([
            'subject_id' => $mathId, 'section_id' => $sectionId,
            'title' => 'Math Quiz 1', 'createdbyteacherid' => $teacherId,
            'assessmenttype' => 'quiz', 'date' => '2025-10-20', 'maxscore' => 20,
        ], 'assessment_id');

        $scienceExamId = DB::table('assessment')->insertGetId([
            'subject_id' => $scienceId, 'section_id' => $sectionId,
            'title' => 'Science Midterm', 'createdbyteacherid' => $teacherId,
            'assessmenttype' => 'exam', 'date' => '2025-11-18', 'maxscore' => 100,
        ], 'assessment_id');

        // Student 1: Ali — strong in math, average in science
        DB::table('assessmentresult')->insert([
            ['assessment_id' => $mathExamId, 'student_id' => $student1Id, 'score' => 92, 'grade' => 'A', 'publishedat' => $now],
            ['assessment_id' => $mathQuizId, 'student_id' => $student1Id, 'score' => 18, 'grade' => 'A', 'publishedat' => $now],
            ['assessment_id' => $scienceExamId, 'student_id' => $student1Id, 'score' => 74, 'grade' => 'C', 'publishedat' => $now],
        ]);

        // Student 2: Fatima — strong in science, average in math
        DB::table('assessmentresult')->insert([
            ['assessment_id' => $mathExamId, 'student_id' => $student2Id, 'score' => 78, 'grade' => 'C', 'publishedat' => $now],
            ['assessment_id' => $mathQuizId, 'student_id' => $student2Id, 'score' => 15, 'grade' => 'B', 'publishedat' => $now],
            ['assessment_id' => $scienceExamId, 'student_id' => $student2Id, 'score' => 95, 'grade' => 'A', 'publishedat' => $now],
        ]);

        // ─────────────────────────────────────────────
        // 9. HOMEWORK
        // ─────────────────────────────────────────────
        $hw1Id = DB::table('homework')->insertGetId([
            'subject_id' => $mathId, 'teacher_id' => $teacherId, 'section_id' => $sectionId,
            'title' => 'Algebra Practice Set', 'description' => 'Complete exercises 1-20 from chapter 5',
            'due_date' => Carbon::now()->addDays(3)->toDateString(),
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $hw2Id = DB::table('homework')->insertGetId([
            'subject_id' => $scienceId, 'teacher_id' => $teacherId, 'section_id' => $sectionId,
            'title' => 'Lab Report: Photosynthesis', 'description' => 'Write up the photosynthesis experiment results',
            'due_date' => Carbon::now()->addDays(7)->toDateString(),
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $hw3Id = DB::table('homework')->insertGetId([
            'subject_id' => $englishId, 'teacher_id' => $teacher2Id, 'section_id' => $sectionId,
            'title' => 'Essay: My Favorite Book', 'description' => 'Write a 500-word essay about your favorite book',
            'due_date' => Carbon::now()->subDays(2)->toDateString(),
            'created_at' => $now, 'updated_at' => $now,
        ]);

        // ─────────────────────────────────────────────
        // 9b. HOMEWORK SUBMISSIONS
        // ─────────────────────────────────────────────
        DB::table('homeworksubmission')->insert([
            // Ali submitted the essay (overdue) — graded
            ['homework_id' => $hw3Id, 'student_id' => $student1Id, 'submittedat' => Carbon::now()->subDay(), 'score' => 85, 'status' => 'graded'],
            // Fatima submitted the essay — graded
            ['homework_id' => $hw3Id, 'student_id' => $student2Id, 'submittedat' => Carbon::now()->subDays(3), 'score' => 92, 'status' => 'graded'],
            // Ali submitted algebra — pending grading
            ['homework_id' => $hw1Id, 'student_id' => $student1Id, 'submittedat' => $now, 'score' => null, 'status' => 'submitted'],
        ]);

        // ─────────────────────────────────────────────
        // 10. ATTENDANCE (2 weeks of sessions)
        // ─────────────────────────────────────────────
        $attendanceDays = [];
        for ($i = 13; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            if ($date->isWeekday()) {
                $attendanceDays[] = $date->toDateString();
            }
        }

        foreach ($attendanceDays as $date) {
            $sessionId = DB::table('attendancesession')->insertGetId([
                'section_id' => $sectionId, 'date' => $date,
            ], 'session_id');

            // Ali: mostly present, 1 absent, 1 late
            $aliStatus = 'present';
            if ($date === $attendanceDays[2]) $aliStatus = 'absent';
            if ($date === $attendanceDays[5]) $aliStatus = 'late';

            // Fatima: always present except 1 excused
            $fatimaStatus = 'present';
            if ($date === $attendanceDays[3]) $fatimaStatus = 'excused';

            DB::table('studentattendance')->insert([
                ['session_id' => $sessionId, 'student_id' => $student1Id, 'status' => $aliStatus, 'capturedbyuserid' => $teacherUserId],
                ['session_id' => $sessionId, 'student_id' => $student2Id, 'status' => $fatimaStatus, 'capturedbyuserid' => $teacherUserId],
            ]);
        }

        // ─────────────────────────────────────────────
        // 11. NOTIFICATIONS + WARNINGS
        // ─────────────────────────────────────────────
        $note1Id = DB::table('notification')->insertGetId([
            'title' => 'School Trip: Science Museum - March 15',
            'createdbyuserid' => $adminUserId, 'channel' => 'general',
            'created_at' => $now,
        ], 'notification_id');

        $note2Id = DB::table('notification')->insertGetId([
            'title' => 'Parent-Teacher Meeting on April 10',
            'createdbyuserid' => $adminUserId, 'channel' => 'general',
            'created_at' => $now,
        ], 'notification_id');

        $warning1Id = DB::table('notification')->insertGetId([
            'title' => 'Ali was absent without excuse on ' . $attendanceDays[2],
            'createdbyuserid' => $teacherUserId, 'channel' => 'warning',
            'created_at' => $now,
        ], 'notification_id');

        $warning2Id = DB::table('notification')->insertGetId([
            'title' => 'Ali has been disruptive in class',
            'createdbyuserid' => $teacherUserId, 'channel' => 'warning',
            'created_at' => $now,
        ], 'notification_id');

        // Notifications → students
        DB::table('notificationrecipient')->insert([
            ['notification_id' => $note1Id, 'user_id' => $student1UserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
            ['notification_id' => $note1Id, 'user_id' => $student2UserId, 'status' => 'read', 'deliveredat' => $now, 'readat' => $now],
            ['notification_id' => $note2Id, 'user_id' => $student1UserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
            ['notification_id' => $note2Id, 'user_id' => $student2UserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
        ]);

        // Warnings → Ali (student) + parent
        DB::table('notificationrecipient')->insert([
            ['notification_id' => $warning1Id, 'user_id' => $student1UserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
            ['notification_id' => $warning1Id, 'user_id' => $parentUserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
            ['notification_id' => $warning2Id, 'user_id' => $student1UserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
            ['notification_id' => $warning2Id, 'user_id' => $parentUserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
        ]);

        // General notes → parent
        DB::table('notificationrecipient')->insert([
            ['notification_id' => $note1Id, 'user_id' => $parentUserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
            ['notification_id' => $note2Id, 'user_id' => $parentUserId, 'status' => 'unread', 'deliveredat' => $now, 'readat' => null],
        ]);

        // ─────────────────────────────────────────────
        // 11b. BEHAVIOR LOGS
        // ─────────────────────────────────────────────
        DB::table('behaviorlog')->insert([
            [
                'student_id' => $student1Id, 'teacher_id' => $teacherId, 'section_id' => $sectionId,
                'type' => 'negative', 'title' => 'Disruptive in class',
                'description' => 'Ali was talking loudly and distracting other students during the math lesson.',
                'date' => Carbon::now()->subDays(3)->toDateString(), 'notify_parent' => true,
                'created_at' => $now, 'updated_at' => $now,
            ],
            [
                'student_id' => $student1Id, 'teacher_id' => $teacherId, 'section_id' => $sectionId,
                'type' => 'positive', 'title' => 'Helped a classmate',
                'description' => 'Ali helped Fatima understand the algebra homework during break.',
                'date' => Carbon::now()->subDays(1)->toDateString(), 'notify_parent' => false,
                'created_at' => $now, 'updated_at' => $now,
            ],
            [
                'student_id' => $student2Id, 'teacher_id' => $teacherId, 'section_id' => $sectionId,
                'type' => 'positive', 'title' => 'Excellent participation',
                'description' => 'Fatima actively participated in the science lab and led her group.',
                'date' => Carbon::now()->subDays(2)->toDateString(), 'notify_parent' => false,
                'created_at' => $now, 'updated_at' => $now,
            ],
        ]);

        // ─────────────────────────────────────────────
        // 12. MESSAGES (teacher ↔ parent)
        // ─────────────────────────────────────────────
        DB::table('messages')->insert([
            [
                'sender_id' => $teacherUserId, 'receiver_id' => $parentUserId,
                'student_id' => $student1Id, 'subject' => 'Ali\'s Math Progress',
                'body' => 'Ali is doing great in math but needs to focus more during class.',
                'read_at' => null, 'created_at' => $now->copy()->subDays(3), 'updated_at' => $now->copy()->subDays(3),
            ],
            [
                'sender_id' => $parentUserId, 'receiver_id' => $teacherUserId,
                'student_id' => $student1Id, 'subject' => 'Re: Ali\'s Math Progress',
                'body' => 'Thank you for letting me know. I will talk to him about it.',
                'read_at' => $now->copy()->subDays(2), 'created_at' => $now->copy()->subDays(2), 'updated_at' => $now->copy()->subDays(2),
            ],
        ]);

        // ─────────────────────────────────────────────
        // 13. COMPLAINTS
        // ─────────────────────────────────────────────
        DB::table('complaint')->insert([
            [
                'parent_id' => $parentId, 'student_id' => $student1Id,
                'subject' => 'Bullying Incident',
                'body' => 'My son Ali reported being bullied during recess. Please investigate.',
                'status' => 'open', 'admin_reply' => null, 'resolved_at' => null,
                'created_at' => $now->copy()->subDay(), 'updated_at' => $now->copy()->subDay(),
            ],
            [
                'parent_id' => $parentId, 'student_id' => null,
                'subject' => 'Cafeteria Food Quality',
                'body' => 'The lunch menu could use more variety and healthier options.',
                'status' => 'resolved', 'admin_reply' => 'Thank you for your feedback. We have updated the menu.',
                'resolved_at' => $now, 'created_at' => $now->copy()->subDays(5), 'updated_at' => $now,
            ],
        ]);

        // ─────────────────────────────────────────────
        // 14. BUS DRIVER
        // ─────────────────────────────────────────────

        // 14a. User + driver profile
        $driverUserId = DB::table('users')->insertGetId([
            'name' => 'Khalid Mansour', 'email' => 'driver@school.test',
            'phone' => '0505555555', 'password' => $password,
            'role_type' => 'driver', 'is_active' => true,
            'created_at' => $now, 'updated_at' => $now,
        ]);

        $driverId = DB::table('driver')->insertGetId([
            'user_id' => $driverUserId,
        ], 'driver_id');

        // 14b. Bus
        $busId = DB::table('bus')->insertGetId([
            'plate_number' => 'SBQ-4231',
        ], 'bus_id');

        // 14c. Assign bus to driver
        DB::table('driverassignment')->insert([
            'driver_id' => $driverId,
            'bus_id'    => $busId,
        ]);

        // 14d. Route with 3 ordered stops
        $routeId = DB::table('route')->insertGetId([
            'name' => 'Route A – North District',
        ], 'route_id');

        $stop1Id = DB::table('routestop')->insertGetId([
            'route_id' => $routeId, 'name' => 'Al-Noor Mosque',
            'stoporder' => 1, 'latitude' => 24.7136, 'longitude' => 46.6753,
        ], 'stop_id');

        $stop2Id = DB::table('routestop')->insertGetId([
            'route_id' => $routeId, 'name' => 'Central Market',
            'stoporder' => 2, 'latitude' => 24.7200, 'longitude' => 46.6820,
        ], 'stop_id');

        $stop3Id = DB::table('routestop')->insertGetId([
            'route_id' => $routeId, 'name' => 'School Main Gate',
            'stoporder' => 3, 'latitude' => 24.7268, 'longitude' => 46.6911,
        ], 'stop_id');

        // 14e. Assign students to the bus / route / stop
        DB::table('studentbusassignment')->insert([
            // Ali boards at Stop 1 (Al-Noor Mosque)
            [
                'student_id' => $student1Id, 'bus_id' => $busId,
                'route_id' => $routeId, 'stop_id' => $stop1Id,
            ],
            // Fatima boards at Stop 2 (Central Market)
            [
                'student_id' => $student2Id, 'bus_id' => $busId,
                'route_id' => $routeId, 'stop_id' => $stop2Id,
            ],
        ]);

        // 14f. Trips
        // Today → scheduled (driver will see it on the home screen)
        $tripTodayId = DB::table('trip')->insertGetId([
            'bus_id' => $busId, 'driver_id' => $driverId,
            'route_id' => $routeId, 'date' => $now->toDateString(),
            'type' => 'morning',
        ], 'trip_id');

        // Yesterday → completed (shows in history with stop events)
        $tripYesterdayId = DB::table('trip')->insertGetId([
            'bus_id' => $busId, 'driver_id' => $driverId,
            'route_id' => $routeId,
            'date' => Carbon::yesterday()->toDateString(),
            'type' => 'morning',
        ], 'trip_id');

        // 3 days ago → afternoon run (history)
        $tripOldId = DB::table('trip')->insertGetId([
            'bus_id' => $busId, 'driver_id' => $driverId,
            'route_id' => $routeId,
            'date' => Carbon::now()->subDays(3)->toDateString(),
            'type' => 'afternoon',
        ], 'trip_id');

        // 14g. Stop events for yesterday's trip (both students boarded + dropped)
        $yBase = Carbon::yesterday()->setTime(7, 0);
        DB::table('tripstopevent')->insert([
            // Ali boarded at stop 1
            [
                'trip_id' => $tripYesterdayId, 'stop_id' => $stop1Id,
                'student_id' => $student1Id, 'eventtype' => 'boarded',
                'eventat' => $yBase->copy()->addMinutes(5),
            ],
            // Ali dropped at stop 3 (school gate)
            [
                'trip_id' => $tripYesterdayId, 'stop_id' => $stop3Id,
                'student_id' => $student1Id, 'eventtype' => 'dropped',
                'eventat' => $yBase->copy()->addMinutes(25),
            ],
            // Fatima boarded at stop 2
            [
                'trip_id' => $tripYesterdayId, 'stop_id' => $stop2Id,
                'student_id' => $student2Id, 'eventtype' => 'boarded',
                'eventat' => $yBase->copy()->addMinutes(12),
            ],
            // Fatima dropped at stop 3
            [
                'trip_id' => $tripYesterdayId, 'stop_id' => $stop3Id,
                'student_id' => $student2Id, 'eventtype' => 'dropped',
                'eventat' => $yBase->copy()->addMinutes(25),
            ],
        ]);

        // 14g-ii. Seed a live GPS ping for today's trip so the parent map
        //         has something to show right away.
        DB::table('trackingping')->insert([
            [
                'trip_id'    => $tripTodayId,
                'latitude'   => 24.7200,   // bus is currently at Stop 2 (Central Market)
                'longitude'  => 46.6820,
                'capturedat' => Carbon::now()->subMinutes(2),
            ],
        ]);

        // Stop events for the 3-days-ago afternoon trip
        $aBase = Carbon::now()->subDays(3)->setTime(13, 30);
        DB::table('tripstopevent')->insert([
            [
                'trip_id' => $tripOldId, 'stop_id' => $stop3Id,
                'student_id' => $student1Id, 'eventtype' => 'boarded',
                'eventat' => $aBase->copy(),
            ],
            [
                'trip_id' => $tripOldId, 'stop_id' => $stop1Id,
                'student_id' => $student1Id, 'eventtype' => 'dropped',
                'eventat' => $aBase->copy()->addMinutes(20),
            ],
            [
                'trip_id' => $tripOldId, 'stop_id' => $stop3Id,
                'student_id' => $student2Id, 'eventtype' => 'boarded',
                'eventat' => $aBase->copy(),
            ],
            [
                'trip_id' => $tripOldId, 'stop_id' => $stop2Id,
                'student_id' => $student2Id, 'eventtype' => 'dropped',
                'eventat' => $aBase->copy()->addMinutes(14),
            ],
        ]);

        // ─────────────────────────────────────────────
        // DONE — Print login cheat sheet
        // ─────────────────────────────────────────────
        $this->command->info('');
        $this->command->info('=== SEEDED TEST ACCOUNTS (password: password123) ===');
        $this->command->info('Admin:   admin@school.test');
        $this->command->info('Teacher: sara@school.test    (id: ' . $teacherId . ')');
        $this->command->info('Teacher: omar@school.test    (id: ' . $teacher2Id . ')');
        $this->command->info('Student: ali@school.test     (id: ' . $student1Id . ')');
        $this->command->info('Student: fatima@school.test  (id: ' . $student2Id . ')');
        $this->command->info('Parent:  parent@school.test  (id: ' . $parentId . ')');
        $this->command->info('Driver:  driver@school.test  (id: ' . $driverId . ')');
        $this->command->info('==========================================');
        $this->command->info('Bus: SBQ-4231  |  Route: Route A – North District');
        $this->command->info('Trips: today (scheduled), yesterday (completed), -3d afternoon (completed)');
        $this->command->info('==========================================');
    }
}
