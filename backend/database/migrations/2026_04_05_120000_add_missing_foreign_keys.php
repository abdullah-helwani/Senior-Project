<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add missing foreign-key constraints across the database.
     *
     * Each FK is added as a named constraint so it can be dropped cleanly
     * on rollback. Cascade rules follow this convention:
     *   - cascade   : child record is meaningless without parent (e.g. enrollment without student)
     *   - set null  : audit/tracking columns where we want to keep the history
     *   - restrict  : reference data we don't want silently deleted (subjects, fee plans)
     */
    public function up(): void
    {
        $fks = $this->constraints();

        foreach ($fks as $fk) {
            [$table, $name, $column, $refTable, $refColumn, $onDelete] = $fk;

            // Skip if already exists (idempotent)
            $exists = DB::selectOne(
                "SELECT 1 FROM information_schema.table_constraints
                 WHERE constraint_name = ? AND table_name = ?",
                [$name, $table]
            );
            if ($exists) {
                continue;
            }

            DB::statement(sprintf(
                'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s) ON DELETE %s',
                $table, $name, $column, $refTable, $refColumn, $onDelete
            ));
        }
    }

    public function down(): void
    {
        foreach (array_reverse($this->constraints()) as $fk) {
            [$table, $name] = $fk;
            DB::statement("ALTER TABLE {$table} DROP CONSTRAINT IF EXISTS {$name}");
        }
    }

    /**
     * [table, constraint_name, column, ref_table, ref_column, on_delete]
     */
    private function constraints(): array
    {
        return [
            // User → role tables
            ['admin',  'admin_user_id_fk',  'user_id', 'users', 'id', 'CASCADE'],
            ['parent', 'parent_user_id_fk', 'user_id', 'users', 'id', 'CASCADE'],
            ['driver', 'driver_user_id_fk', 'user_id', 'users', 'id', 'CASCADE'],

            // Assessments
            ['assessment',       'assessment_subject_id_fk',       'subject_id',          'subjects', 'id', 'RESTRICT'],
            ['assessment',       'assessment_createdby_fk',        'createdbyteacherid',  'teachers', 'id', 'SET NULL'],
            ['assessmentresult', 'assessmentresult_student_id_fk', 'student_id',          'students', 'id', 'CASCADE'],

            // Enrollment
            ['enrollment', 'enrollment_student_id_fk', 'student_id', 'students', 'id', 'CASCADE'],

            // Homework submissions
            ['homeworksubmission', 'homeworksubmission_homework_id_fk', 'homework_id', 'homework', 'id', 'CASCADE'],
            ['homeworksubmission', 'homeworksubmission_student_id_fk',  'student_id',  'students', 'id', 'CASCADE'],

            // Notifications
            ['notification',          'notification_createdby_fk',       'createdbyuserid', 'users', 'id', 'SET NULL'],
            ['notificationrecipient', 'notificationrecipient_user_id_fk', 'user_id',        'users', 'id', 'CASCADE'],

            // Schedule slots
            ['scheduleslot', 'scheduleslot_subject_id_fk', 'subject_id', 'subjects', 'id', 'RESTRICT'],
            ['scheduleslot', 'scheduleslot_teacher_id_fk', 'teacher_id', 'teachers', 'id', 'SET NULL'],

            // Student attendance
            ['studentattendance', 'studentattendance_student_id_fk',  'student_id',       'students', 'id', 'CASCADE'],
            ['studentattendance', 'studentattendance_capturedby_fk',  'capturedbyuserid', 'users',    'id', 'SET NULL'],

            // Teacher assignments
            ['teacherassignment', 'teacherassignment_teacher_id_fk', 'teacher_id', 'teachers', 'id', 'CASCADE'],
            ['teacherassignment', 'teacherassignment_subject_id_fk', 'subject_id', 'subjects', 'id', 'RESTRICT'],

            // Teacher attendance
            ['teacherattendance', 'teacherattendance_teacher_id_fk',  'teacher_id',       'teachers', 'id', 'CASCADE'],
            ['teacherattendance', 'teacherattendance_capturedby_fk',  'capturedbyuserid', 'users',    'id', 'SET NULL'],

            // Teacher availability / vacation
            ['teacheravailability', 'teacheravailability_teacher_id_fk', 'teacher_id', 'teachers', 'id', 'CASCADE'],
            ['vacationrequest',     'vacationrequest_teacher_id_fk',     'teacher_id', 'teachers', 'id', 'CASCADE'],

            // Salary
            ['salarypayment', 'salarypayment_teacher_id_fk', 'teacher_id', 'teachers', 'id', 'RESTRICT'],

            // Student ↔ Guardian
            ['studentguardian', 'studentguardian_student_id_fk', 'student_id', 'students', 'id', 'CASCADE'],

            // Finance (student side)
            ['studentfeeplan', 'studentfeeplan_student_id_fk', 'student_id', 'students', 'id', 'CASCADE'],

            // Transport
            ['studentbusassignment', 'studentbusassignment_student_id_fk', 'student_id', 'students', 'id', 'CASCADE'],
            ['tripstopevent',        'tripstopevent_student_id_fk',        'student_id', 'students', 'id', 'SET NULL'],

            // Surveillance
            ['surveillanceevent', 'surveillanceevent_relatedstudent_fk', 'relatedstudent_id', 'students', 'id', 'SET NULL'],
        ];
    }
};
