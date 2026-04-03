<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\StudentController;
use App\Http\Controllers\Admin\TeacherController;
use App\Http\Controllers\Admin\AssessmentController;
use App\Http\Controllers\Admin\SchoolYearController;
use App\Http\Controllers\Admin\SchoolClassController;
use App\Http\Controllers\Admin\SectionController;
use App\Http\Controllers\Admin\SubjectController;
use App\Http\Controllers\Admin\EnrollmentController;
use App\Http\Controllers\Admin\ParentController as AdminParentController;
use App\Http\Controllers\Admin\ComplaintController as AdminComplaintController;
use App\Http\Controllers\Admin\TeacherAssignmentController;
use App\Http\Controllers\Teacher\ScheduleController;
use App\Http\Controllers\Teacher\HomeworkController;
use App\Http\Controllers\Teacher\MessageController;
use App\Http\Controllers\Teacher\AttendanceController as TeacherAttendanceController;
use App\Http\Controllers\Teacher\PerformanceReportController;
use App\Http\Controllers\Teacher\BehaviorLogController;
use App\Http\Controllers\Student\HomeworkController as StudentHomeworkController;
use App\Http\Controllers\Student\NotificationController as StudentNotificationController;
use App\Http\Controllers\Student\MarksController as StudentMarksController;
use App\Http\Controllers\Student\ScheduleController as StudentScheduleController;
use App\Http\Controllers\Student\AttendanceController as StudentAttendanceController;
use App\Http\Controllers\Student\WarningController as StudentWarningController;
use App\Http\Controllers\ParentControllers\ChildMarksController;
use App\Http\Controllers\ParentControllers\ChildAttendanceController;
use App\Http\Controllers\ParentControllers\BehaviorController;
use App\Http\Controllers\ParentControllers\SchoolNoteController;
use App\Http\Controllers\ParentControllers\MessageController as ParentMessageController;
use App\Http\Controllers\ParentControllers\ComplaintController;

/*
|--------------------------------------------------------------------------
| Auth Routes (public)
|--------------------------------------------------------------------------
*/
Route::post('/login', [AuthController::class, 'login']);

/*
|--------------------------------------------------------------------------
| Protected Routes
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);

    /*
    |--------------------------------------------------------------------------
    | Admin Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:admin')->prefix('admin')->group(function () {

        // Create any user account (student / teacher / parent / admin)
        Route::post('/users', [UserController::class, 'store']);

        // Students — CRUD + search + filter
        Route::get('/students',         [StudentController::class, 'index']);
        Route::post('/students',        [StudentController::class, 'store']);
        Route::get('/students/{id}',    [StudentController::class, 'show']);
        Route::put('/students/{id}',    [StudentController::class, 'update']);
        Route::delete('/students/{id}', [StudentController::class, 'destroy']);

        // Teachers — CRUD + search + filter
        Route::get('/teachers',         [TeacherController::class, 'index']);
        Route::post('/teachers',        [TeacherController::class, 'store']);
        Route::get('/teachers/{id}',    [TeacherController::class, 'show']);
        Route::put('/teachers/{id}',    [TeacherController::class, 'update']);
        Route::delete('/teachers/{id}', [TeacherController::class, 'destroy']);

        // Setup / Reference data
        Route::apiResource('/school-years', SchoolYearController::class);
        Route::apiResource('/classes',      SchoolClassController::class);
        Route::apiResource('/sections',     SectionController::class);
        Route::apiResource('/subjects',     SubjectController::class);

        // Enrollments
        Route::get('/enrollments',         [EnrollmentController::class, 'index']);
        Route::post('/enrollments',        [EnrollmentController::class, 'store']);
        Route::put('/enrollments/{id}',    [EnrollmentController::class, 'update']);
        Route::delete('/enrollments/{id}', [EnrollmentController::class, 'destroy']);

        // Assessments & Marks
        Route::get('/assessments',                    [AssessmentController::class, 'index']);
        Route::post('/assessments',                   [AssessmentController::class, 'store']);
        Route::get('/assessments/{id}',               [AssessmentController::class, 'show']);
        Route::put('/assessments/{id}',               [AssessmentController::class, 'update']);
        Route::delete('/assessments/{id}',            [AssessmentController::class, 'destroy']);
        Route::post('/assessments/{id}/results',      [AssessmentController::class, 'storeResults']);
        Route::get('/assessments/{id}/results',       [AssessmentController::class, 'results']);

        // Teacher Assignments — assign teachers to sections/subjects
        Route::get('/teacher-assignments',         [TeacherAssignmentController::class, 'index']);
        Route::post('/teacher-assignments',        [TeacherAssignmentController::class, 'store']);
        Route::get('/teacher-assignments/{id}',    [TeacherAssignmentController::class, 'show']);
        Route::put('/teacher-assignments/{id}',    [TeacherAssignmentController::class, 'update']);
        Route::delete('/teacher-assignments/{id}', [TeacherAssignmentController::class, 'destroy']);

        // Parents — CRUD + link/unlink children
        Route::get('/parents',                              [AdminParentController::class, 'index']);
        Route::post('/parents',                             [AdminParentController::class, 'store']);
        Route::get('/parents/{id}',                         [AdminParentController::class, 'show']);
        Route::put('/parents/{id}',                         [AdminParentController::class, 'update']);
        Route::delete('/parents/{id}',                      [AdminParentController::class, 'destroy']);
        Route::post('/parents/{id}/children',               [AdminParentController::class, 'addChild']);
        Route::delete('/parents/{id}/children/{studentId}', [AdminParentController::class, 'removeChild']);

        // Complaints — view, review, reply
        Route::get('/complaints',         [AdminComplaintController::class, 'index']);
        Route::get('/complaints/{id}',    [AdminComplaintController::class, 'show']);
        Route::put('/complaints/{id}',    [AdminComplaintController::class, 'update']);
    });

    /*
    |--------------------------------------------------------------------------
    | Teacher Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:teacher')->prefix('teacher')->group(function () {

        // Weekly schedule
        Route::get('/{teacherId}/schedule', [ScheduleController::class, 'index']);

        // Homework — CRUD
        Route::get('/{teacherId}/homework',         [HomeworkController::class, 'index']);
        Route::post('/{teacherId}/homework',        [HomeworkController::class, 'store']);
        Route::get('/{teacherId}/homework/{id}',    [HomeworkController::class, 'show']);
        Route::put('/{teacherId}/homework/{id}',    [HomeworkController::class, 'update']);
        Route::delete('/{teacherId}/homework/{id}', [HomeworkController::class, 'destroy']);

        // Messages to parents
        Route::get('/{teacherId}/messages',      [MessageController::class, 'sent']);
        Route::post('/{teacherId}/messages',     [MessageController::class, 'send']);
        Route::get('/{teacherId}/messages/{id}', [MessageController::class, 'show']);

        // Attendance — record + view per section
        Route::post('/{teacherId}/attendance',   [TeacherAttendanceController::class, 'store']);
        Route::get('/{teacherId}/attendance',    [TeacherAttendanceController::class, 'index']);

        // Weekly performance report
        Route::get('/{teacherId}/performance-report', [PerformanceReportController::class, 'index']);

        // Behavior logs
        Route::get('/{teacherId}/behavior-logs',         [BehaviorLogController::class, 'index']);
        Route::post('/{teacherId}/behavior-logs',        [BehaviorLogController::class, 'store']);
        Route::get('/{teacherId}/behavior-logs/{logId}', [BehaviorLogController::class, 'show']);
    });

    /*
    |--------------------------------------------------------------------------
    | Student Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:student')->prefix('student')->group(function () {

        // Homework — view assigned homework
        Route::get('/{studentId}/homework',      [StudentHomeworkController::class, 'index']);
        Route::get('/{studentId}/homework/{id}', [StudentHomeworkController::class, 'show']);

        // Marks / Grades
        Route::get('/{studentId}/marks',         [StudentMarksController::class, 'index']);
        Route::get('/{studentId}/marks/summary', [StudentMarksController::class, 'summary']);

        // Weekly schedule / timetable
        Route::get('/{studentId}/schedule', [StudentScheduleController::class, 'index']);

        // Attendance
        Route::get('/{studentId}/attendance', [StudentAttendanceController::class, 'index']);

        // Warnings
        Route::get('/{studentId}/warnings', [StudentWarningController::class, 'index']);

        // Notifications
        Route::get('/{studentId}/notifications',                    [StudentNotificationController::class, 'index']);
        Route::put('/{studentId}/notifications/{recipientId}/read', [StudentNotificationController::class, 'markRead']);
        Route::put('/{studentId}/notifications/read-all',           [StudentNotificationController::class, 'markAllRead']);
    });

    /*
    |--------------------------------------------------------------------------
    | Parent Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:parent')->prefix('parent')->group(function () {

        // Child's marks
        Route::get('/{parentId}/children/{studentId}/marks',         [ChildMarksController::class, 'index']);
        Route::get('/{parentId}/children/{studentId}/marks/summary', [ChildMarksController::class, 'summary']);

        // Child's attendance
        Route::get('/{parentId}/children/{studentId}/attendance', [ChildAttendanceController::class, 'index']);

        // Child's behavior / warnings
        Route::get('/{parentId}/children/{studentId}/behavior', [BehaviorController::class, 'index']);

        // School notes (notifications excluding warnings)
        Route::get('/{parentId}/notes',                    [SchoolNoteController::class, 'index']);
        Route::put('/{parentId}/notes/{recipientId}/read', [SchoolNoteController::class, 'markRead']);

        // Messages (to/from teachers)
        Route::get('/{parentId}/messages',      [ParentMessageController::class, 'index']);
        Route::post('/{parentId}/messages',     [ParentMessageController::class, 'send']);
        Route::get('/{parentId}/messages/{id}', [ParentMessageController::class, 'show']);

        // Complaints
        Route::get('/{parentId}/complaints',      [ComplaintController::class, 'index']);
        Route::post('/{parentId}/complaints',     [ComplaintController::class, 'store']);
        Route::get('/{parentId}/complaints/{id}', [ComplaintController::class, 'show']);
    });
});
