<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\StudentController;
use App\Http\Controllers\Admin\TeacherController;
use App\Http\Controllers\Admin\AssessmentController;
use App\Http\Controllers\Admin\SchoolYearController;
use App\Http\Controllers\Admin\SchoolClassController;
use App\Http\Controllers\Admin\SectionController;
use App\Http\Controllers\Admin\SubjectController;
use App\Http\Controllers\Admin\EnrollmentController;
use App\Http\Controllers\Teacher\ScheduleController;
use App\Http\Controllers\Teacher\HomeworkController;
use App\Http\Controllers\Teacher\MessageController;

/*
|--------------------------------------------------------------------------
| Admin Routes
|--------------------------------------------------------------------------
*/
Route::prefix('admin')->group(function () {

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
    Route::apiResource('/school-years',  SchoolYearController::class);
    Route::apiResource('/classes',       SchoolClassController::class);
    Route::apiResource('/sections',      SectionController::class);
    Route::apiResource('/subjects',      SubjectController::class);

    // Enrollments
    Route::get('/enrollments',         [EnrollmentController::class, 'index']);
    Route::post('/enrollments',        [EnrollmentController::class, 'store']);
    Route::put('/enrollments/{id}',    [EnrollmentController::class, 'update']);
    Route::delete('/enrollments/{id}', [EnrollmentController::class, 'destroy']);

    // Assessments & Marks
    Route::get('/assessments',                          [AssessmentController::class, 'index']);
    Route::post('/assessments',                         [AssessmentController::class, 'store']);
    Route::get('/assessments/{id}',                     [AssessmentController::class, 'show']);
    Route::put('/assessments/{id}',                     [AssessmentController::class, 'update']);
    Route::delete('/assessments/{id}',                  [AssessmentController::class, 'destroy']);
    Route::post('/assessments/{id}/results',            [AssessmentController::class, 'storeResults']);
    Route::get('/assessments/{id}/results',             [AssessmentController::class, 'results']);
});

/*
|--------------------------------------------------------------------------
| Teacher Routes
|--------------------------------------------------------------------------
*/
Route::prefix('teacher')->group(function () {

    // Weekly schedule
    Route::get('/{teacherId}/schedule', [ScheduleController::class, 'index']);

    // Homework — CRUD
    Route::get('/{teacherId}/homework',          [HomeworkController::class, 'index']);
    Route::post('/{teacherId}/homework',         [HomeworkController::class, 'store']);
    Route::get('/{teacherId}/homework/{id}',     [HomeworkController::class, 'show']);
    Route::put('/{teacherId}/homework/{id}',     [HomeworkController::class, 'update']);
    Route::delete('/{teacherId}/homework/{id}',  [HomeworkController::class, 'destroy']);

    // Messages to parents
    Route::get('/{teacherId}/messages',          [MessageController::class, 'sent']);
    Route::post('/{teacherId}/messages',         [MessageController::class, 'send']);
    Route::get('/{teacherId}/messages/{id}',     [MessageController::class, 'show']);
});
