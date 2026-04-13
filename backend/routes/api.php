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
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\TeacherAssignmentController;
use App\Http\Controllers\Admin\ScheduleController as AdminScheduleController;
use App\Http\Controllers\Admin\AttendanceController as AdminAttendanceController;
use App\Http\Controllers\Admin\NotificationController as AdminNotificationController;
use App\Http\Controllers\Admin\BehaviorLogController as AdminBehaviorLogController;
use App\Http\Controllers\Admin\SalaryPaymentController;
use App\Http\Controllers\Admin\FeePlanController;
use App\Http\Controllers\Admin\StudentFeePlanController;
use App\Http\Controllers\Admin\InvoiceController;
use App\Http\Controllers\Admin\PaymentController;
use App\Http\Controllers\Teacher\ScheduleController;
use App\Http\Controllers\Teacher\HomeworkController;
use App\Http\Controllers\Teacher\MessageController;
use App\Http\Controllers\Teacher\AttendanceController as TeacherAttendanceController;
use App\Http\Controllers\Teacher\PerformanceReportController;
use App\Http\Controllers\Teacher\BehaviorLogController;
use App\Http\Controllers\Teacher\ProfileController as TeacherProfileController;
use App\Http\Controllers\Teacher\SalaryController as TeacherSalaryController;
use App\Http\Controllers\Student\HomeworkController as StudentHomeworkController;
use App\Http\Controllers\Student\NotificationController as StudentNotificationController;
use App\Http\Controllers\Student\MarksController as StudentMarksController;
use App\Http\Controllers\Student\ScheduleController as StudentScheduleController;
use App\Http\Controllers\Student\AttendanceController as StudentAttendanceController;
use App\Http\Controllers\Student\WarningController as StudentWarningController;
use App\Http\Controllers\Student\ProfileController as StudentProfileController;
use App\Http\Controllers\Student\SubmissionController as StudentSubmissionController;
use App\Http\Controllers\ParentControllers\ChildMarksController;
use App\Http\Controllers\ParentControllers\ChildAttendanceController;
use App\Http\Controllers\ParentControllers\BehaviorController;
use App\Http\Controllers\ParentControllers\SchoolNoteController;
use App\Http\Controllers\ParentControllers\MessageController as ParentMessageController;
use App\Http\Controllers\ParentControllers\ComplaintController;
use App\Http\Controllers\ParentControllers\ChildrenController;
use App\Http\Controllers\ParentControllers\ProfileController as ParentProfileController;
use App\Http\Controllers\ParentControllers\ChildHomeworkController;
use App\Http\Controllers\ParentControllers\ChildScheduleController;
use App\Http\Controllers\ParentControllers\InvoiceController as ParentInvoiceController;
use App\Http\Controllers\ParentControllers\PaymentController as ParentPaymentController;
use App\Http\Controllers\ParentControllers\ChildBusController;
use App\Http\Controllers\Admin\BusController;
use App\Http\Controllers\Admin\DriverController;
use App\Http\Controllers\Admin\DriverAssignmentController;
use App\Http\Controllers\Admin\BusRouteController;
use App\Http\Controllers\Admin\RouteStopController;
use App\Http\Controllers\Admin\StudentBusAssignmentController;
use App\Http\Controllers\Admin\TripController;
use App\Http\Controllers\Admin\TrackingController as AdminTrackingController;
use App\Http\Controllers\Admin\VacationRequestController as AdminVacationRequestController;
use App\Http\Controllers\Admin\TeacherAvailabilityController;
use App\Http\Controllers\Admin\AnalyticsReportController;
use App\Http\Controllers\Teacher\VacationRequestController as TeacherVacationRequestController;
use App\Http\Controllers\Teacher\AvailabilityController as TeacherAvailabilityCtrl;
use App\Http\Controllers\Driver\TripController as DriverTripController;
use App\Http\Controllers\Driver\ProfileController as DriverProfileController;
use App\Http\Controllers\Driver\TrackingController as DriverTrackingController;
use App\Http\Controllers\Driver\StopEventController as DriverStopEventController;
use App\Http\Controllers\Student\BusController as StudentBusController;
use App\Http\Controllers\Admin\ExportController;
use App\Http\Controllers\Admin\AuditLogController;
use App\Http\Controllers\Admin\CameraController;
use App\Http\Controllers\Admin\SurveillanceEventController;
use App\Http\Controllers\Ai\SurveillanceController as AiSurveillanceController;
use App\Http\Controllers\Admin\ReportCardController;
use App\Http\Controllers\AssessmentCalendarController;
use App\Http\Controllers\ParentControllers\StripeController;
use App\Http\Controllers\Webhook\StripeWebhookController;

/*
|--------------------------------------------------------------------------
| Auth Routes (public)
|--------------------------------------------------------------------------
*/
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');

/*
|--------------------------------------------------------------------------
| Webhooks (no auth — verified by signature)
|--------------------------------------------------------------------------
*/
Route::post('/webhooks/stripe', [StripeWebhookController::class, 'handle']);

/*
|--------------------------------------------------------------------------
| Protected Routes
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/change-password', [AuthController::class, 'changePassword']);
    Route::post('/profile-picture', [AuthController::class, 'updateProfilePicture']);
    Route::delete('/profile-picture', [AuthController::class, 'deleteProfilePicture']);

    /*
    |--------------------------------------------------------------------------
    | Admin Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:admin')->prefix('admin')->group(function () {

        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'index']);

        // Create any user account (student / teacher / parent / admin)
        Route::get('/users',      [UserController::class, 'index']);
        Route::get('/users/{id}', [UserController::class, 'show']);
        Route::post('/users',     [UserController::class, 'store']);
        Route::put('/users/{id}', [UserController::class, 'update']);
        Route::put('/users/{id}/reset-password', [UserController::class, 'resetPassword']);
        Route::put('/users/{id}/toggle-active', [UserController::class, 'toggleActive']);
        Route::post('/users/{id}/profile-picture', [UserController::class, 'updateProfilePicture']);
        Route::delete('/users/{id}/profile-picture', [UserController::class, 'deleteProfilePicture']);

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

        // Attendance — record, view, manage sessions
        Route::get('/attendance',                                       [AdminAttendanceController::class, 'index']);
        Route::post('/attendance',                                      [AdminAttendanceController::class, 'store']);
        Route::get('/attendance/student/{studentId}',                   [AdminAttendanceController::class, 'studentSummary']);
        Route::get('/attendance/{sessionId}',                           [AdminAttendanceController::class, 'show']);
        Route::put('/attendance/{sessionId}/records/{attendanceId}',    [AdminAttendanceController::class, 'updateRecord']);
        Route::delete('/attendance/{sessionId}',                        [AdminAttendanceController::class, 'destroy']);

        // Schedules — CRUD + slot management
        Route::get('/schedules',                          [AdminScheduleController::class, 'index']);
        Route::post('/schedules',                         [AdminScheduleController::class, 'store']);
        Route::get('/schedules/{id}',                     [AdminScheduleController::class, 'show']);
        Route::put('/schedules/{id}',                     [AdminScheduleController::class, 'update']);
        Route::delete('/schedules/{id}',                  [AdminScheduleController::class, 'destroy']);
        Route::post('/schedules/{id}/slots',              [AdminScheduleController::class, 'addSlot']);
        Route::put('/schedules/{id}/slots/{slotId}',      [AdminScheduleController::class, 'updateSlot']);
        Route::delete('/schedules/{id}/slots/{slotId}',   [AdminScheduleController::class, 'removeSlot']);

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

        // Behavior Logs — view all across teachers
        Route::get('/behavior-logs',      [AdminBehaviorLogController::class, 'index']);
        Route::get('/behavior-logs/{id}', [AdminBehaviorLogController::class, 'show']);
        Route::delete('/behavior-logs/{id}', [AdminBehaviorLogController::class, 'destroy']);

        // Notifications — broadcast + manage
        Route::get('/notifications',      [AdminNotificationController::class, 'index']);
        Route::post('/notifications',     [AdminNotificationController::class, 'store']);
        Route::get('/notifications/{id}', [AdminNotificationController::class, 'show']);
        Route::delete('/notifications/{id}', [AdminNotificationController::class, 'destroy']);

        // Complaints — view, review, reply
        Route::get('/complaints',         [AdminComplaintController::class, 'index']);
        Route::get('/complaints/{id}',    [AdminComplaintController::class, 'show']);
        Route::put('/complaints/{id}',    [AdminComplaintController::class, 'update']);

        // Salary Payments — record + manage teacher salaries
        Route::get('/salary-payments',         [SalaryPaymentController::class, 'index']);
        Route::post('/salary-payments',        [SalaryPaymentController::class, 'store']);
        Route::get('/salary-payments/{id}',    [SalaryPaymentController::class, 'show']);
        Route::put('/salary-payments/{id}',    [SalaryPaymentController::class, 'update']);
        Route::delete('/salary-payments/{id}', [SalaryPaymentController::class, 'destroy']);

        // Fee Plans — define tuition/fee structures per school year
        Route::get('/fee-plans',         [FeePlanController::class, 'index']);
        Route::post('/fee-plans',        [FeePlanController::class, 'store']);
        Route::get('/fee-plans/{id}',    [FeePlanController::class, 'show']);
        Route::put('/fee-plans/{id}',    [FeePlanController::class, 'update']);
        Route::delete('/fee-plans/{id}', [FeePlanController::class, 'destroy']);

        // Student Fee Plans — assign plans to students, track balances
        Route::get('/student-fee-plans',         [StudentFeePlanController::class, 'index']);
        Route::post('/student-fee-plans',        [StudentFeePlanController::class, 'store']);
        Route::get('/student-fee-plans/{id}',    [StudentFeePlanController::class, 'show']);
        Route::put('/student-fee-plans/{id}',    [StudentFeePlanController::class, 'update']);
        Route::delete('/student-fee-plans/{id}', [StudentFeePlanController::class, 'destroy']);

        // Invoices — generate + manage student bills
        Route::get('/invoices',         [InvoiceController::class, 'index']);
        Route::post('/invoices',        [InvoiceController::class, 'store']);
        Route::get('/invoices/{id}',    [InvoiceController::class, 'show']);
        Route::put('/invoices/{id}',    [InvoiceController::class, 'update']);
        Route::delete('/invoices/{id}', [InvoiceController::class, 'destroy']);

        // Payments — record + void payments against invoices
        Route::get('/payments',         [PaymentController::class, 'index']);
        Route::post('/payments',        [PaymentController::class, 'store']);
        Route::get('/payments/{id}',    [PaymentController::class, 'show']);
        Route::delete('/payments/{id}', [PaymentController::class, 'destroy']);

        // Transport — Buses
        Route::get('/buses',         [BusController::class, 'index']);
        Route::post('/buses',        [BusController::class, 'store']);
        Route::get('/buses/{id}',    [BusController::class, 'show']);
        Route::put('/buses/{id}',    [BusController::class, 'update']);
        Route::delete('/buses/{id}', [BusController::class, 'destroy']);

        // Transport — Drivers
        Route::get('/drivers',         [DriverController::class, 'index']);
        Route::post('/drivers',        [DriverController::class, 'store']);
        Route::get('/drivers/{id}',    [DriverController::class, 'show']);
        Route::put('/drivers/{id}',    [DriverController::class, 'update']);
        Route::delete('/drivers/{id}', [DriverController::class, 'destroy']);

        // Transport — Driver ↔ Bus assignments
        Route::get('/driver-assignments',         [DriverAssignmentController::class, 'index']);
        Route::post('/driver-assignments',        [DriverAssignmentController::class, 'store']);
        Route::get('/driver-assignments/{id}',    [DriverAssignmentController::class, 'show']);
        Route::delete('/driver-assignments/{id}', [DriverAssignmentController::class, 'destroy']);

        // Transport — Routes
        Route::get('/bus-routes',         [BusRouteController::class, 'index']);
        Route::post('/bus-routes',        [BusRouteController::class, 'store']);
        Route::get('/bus-routes/{id}',    [BusRouteController::class, 'show']);
        Route::put('/bus-routes/{id}',    [BusRouteController::class, 'update']);
        Route::delete('/bus-routes/{id}', [BusRouteController::class, 'destroy']);

        // Transport — Route stops
        Route::get('/route-stops',         [RouteStopController::class, 'index']);
        Route::post('/route-stops',        [RouteStopController::class, 'store']);
        Route::get('/route-stops/{id}',    [RouteStopController::class, 'show']);
        Route::put('/route-stops/{id}',    [RouteStopController::class, 'update']);
        Route::delete('/route-stops/{id}', [RouteStopController::class, 'destroy']);

        // Transport — Student ↔ Bus assignments
        Route::get('/student-bus-assignments',         [StudentBusAssignmentController::class, 'index']);
        Route::post('/student-bus-assignments',        [StudentBusAssignmentController::class, 'store']);
        Route::get('/student-bus-assignments/{id}',    [StudentBusAssignmentController::class, 'show']);
        Route::put('/student-bus-assignments/{id}',    [StudentBusAssignmentController::class, 'update']);
        Route::delete('/student-bus-assignments/{id}', [StudentBusAssignmentController::class, 'destroy']);

        // Transport — Trips
        Route::get('/trips',         [TripController::class, 'index']);
        Route::post('/trips',        [TripController::class, 'store']);
        Route::get('/trips/{id}',    [TripController::class, 'show']);
        Route::put('/trips/{id}',    [TripController::class, 'update']);
        Route::delete('/trips/{id}', [TripController::class, 'destroy']);

        // Transport — Trip live tracking
        Route::get('/trips/{tripId}/location', [AdminTrackingController::class, 'location']);
        Route::get('/trips/{tripId}/trail',    [AdminTrackingController::class, 'trail']);
        Route::get('/trips/{tripId}/events',   [AdminTrackingController::class, 'events']);

        // Vacation Requests — review + approve/reject
        Route::get('/vacation-requests',         [AdminVacationRequestController::class, 'index']);
        Route::get('/vacation-requests/{id}',    [AdminVacationRequestController::class, 'show']);
        Route::put('/vacation-requests/{id}',    [AdminVacationRequestController::class, 'update']);
        Route::delete('/vacation-requests/{id}', [AdminVacationRequestController::class, 'destroy']);

        // Teacher Availability — manage teacher schedules
        Route::get('/teacher-availability',         [TeacherAvailabilityController::class, 'index']);
        Route::post('/teacher-availability',        [TeacherAvailabilityController::class, 'store']);
        Route::get('/teacher-availability/{id}',    [TeacherAvailabilityController::class, 'show']);
        Route::put('/teacher-availability/{id}',    [TeacherAvailabilityController::class, 'update']);
        Route::delete('/teacher-availability/{id}', [TeacherAvailabilityController::class, 'destroy']);

        // Analytics & Reports — generate + view reports
        Route::get('/analytics/reports',         [AnalyticsReportController::class, 'index']);
        Route::post('/analytics/reports',        [AnalyticsReportController::class, 'store']);
        Route::get('/analytics/reports/{id}',    [AnalyticsReportController::class, 'show']);
        Route::delete('/analytics/reports/{id}', [AnalyticsReportController::class, 'destroy']);

        // Analytics — live stats (no saved report)
        Route::get('/analytics/live/attendance', [AnalyticsReportController::class, 'liveAttendance']);
        Route::get('/analytics/live/academic',   [AnalyticsReportController::class, 'liveAcademic']);
        Route::get('/analytics/live/behavior',   [AnalyticsReportController::class, 'liveBehavior']);

        // Audit Logs — track who changed what and when
        Route::get('/audit-logs',                                  [AuditLogController::class, 'index']);
        Route::get('/audit-logs/{id}',                             [AuditLogController::class, 'show']);
        Route::get('/audit-logs/user/{userId}',                    [AuditLogController::class, 'userHistory']);
        Route::get('/audit-logs/resource/{resource}/{resourceId}', [AuditLogController::class, 'resourceHistory']);

        // Export — CSV + PDF downloads
        Route::get('/export/marks/csv',       [ExportController::class, 'marksCsv']);
        Route::get('/export/marks/pdf',       [ExportController::class, 'marksPdf']);
        Route::get('/export/attendance/csv',  [ExportController::class, 'attendanceCsv']);
        Route::get('/export/attendance/pdf',  [ExportController::class, 'attendancePdf']);

        // Cameras — CRUD
        Route::get('/cameras',         [CameraController::class, 'index']);
        Route::post('/cameras',        [CameraController::class, 'store']);
        Route::get('/cameras/{id}',    [CameraController::class, 'show']);
        Route::put('/cameras/{id}',    [CameraController::class, 'update']);
        Route::delete('/cameras/{id}', [CameraController::class, 'destroy']);

        // Surveillance Events — view + filter + summary
        Route::get('/surveillance-events',         [SurveillanceEventController::class, 'index']);
        Route::get('/surveillance-events/summary',  [SurveillanceEventController::class, 'summary']);
        Route::get('/surveillance-events/{id}',    [SurveillanceEventController::class, 'show']);
        Route::delete('/surveillance-events/{id}', [SurveillanceEventController::class, 'destroy']);

        // Report Cards — PDF generation
        Route::get('/report-cards/student/{studentId}',         [ReportCardController::class, 'student']);
        Route::get('/report-cards/student/{studentId}/preview', [ReportCardController::class, 'preview']);
        Route::get('/report-cards/section/{sectionId}',         [ReportCardController::class, 'section']);

        // Assessment Calendar — all sections
        Route::get('/assessment-calendar', [AssessmentCalendarController::class, 'adminCalendar']);
    });

    /*
    |--------------------------------------------------------------------------
    | Teacher Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:teacher')->prefix('teacher')->group(function () {

        // Profile
        Route::get('/{teacherId}/profile', [TeacherProfileController::class, 'show']);

        // Weekly schedule
        Route::get('/{teacherId}/schedule', [ScheduleController::class, 'index']);

        // Homework — CRUD
        Route::get('/{teacherId}/homework',         [HomeworkController::class, 'index']);
        Route::post('/{teacherId}/homework',        [HomeworkController::class, 'store']);
        Route::get('/{teacherId}/homework/{id}',    [HomeworkController::class, 'show']);
        Route::put('/{teacherId}/homework/{id}',    [HomeworkController::class, 'update']);
        Route::delete('/{teacherId}/homework/{id}', [HomeworkController::class, 'destroy']);
        Route::get('/{teacherId}/homework/{id}/submissions',                        [HomeworkController::class, 'submissions']);
        Route::put('/{teacherId}/homework/{id}/submissions/{submissionId}/grade',   [HomeworkController::class, 'grade']);

        // Messages to/from parents
        Route::get('/{teacherId}/messages',       [MessageController::class, 'sent']);
        Route::get('/{teacherId}/messages/inbox', [MessageController::class, 'inbox']);
        Route::post('/{teacherId}/messages',      [MessageController::class, 'send']);
        Route::get('/{teacherId}/messages/{id}',  [MessageController::class, 'show']);

        // Attendance — record + view per section
        Route::post('/{teacherId}/attendance',   [TeacherAttendanceController::class, 'store']);
        Route::get('/{teacherId}/attendance',    [TeacherAttendanceController::class, 'index']);

        // Weekly performance report
        Route::get('/{teacherId}/performance-report', [PerformanceReportController::class, 'index']);

        // Behavior logs
        Route::get('/{teacherId}/behavior-logs',         [BehaviorLogController::class, 'index']);
        Route::post('/{teacherId}/behavior-logs',        [BehaviorLogController::class, 'store']);
        Route::get('/{teacherId}/behavior-logs/{logId}', [BehaviorLogController::class, 'show']);

        // Salary — view own salary history
        Route::get('/{teacherId}/salary',      [TeacherSalaryController::class, 'index']);
        Route::get('/{teacherId}/salary/{id}', [TeacherSalaryController::class, 'show']);

        // Vacation Requests — submit + view own requests
        Route::get('/{teacherId}/vacation-requests',         [TeacherVacationRequestController::class, 'index']);
        Route::post('/{teacherId}/vacation-requests',        [TeacherVacationRequestController::class, 'store']);
        Route::get('/{teacherId}/vacation-requests/{id}',    [TeacherVacationRequestController::class, 'show']);
        Route::delete('/{teacherId}/vacation-requests/{id}', [TeacherVacationRequestController::class, 'destroy']);

        // Assessment Calendar — upcoming exams/assessments for teacher's sections
        Route::get('/{teacherId}/assessment-calendar', [AssessmentCalendarController::class, 'teacherCalendar']);

        // Availability — manage own availability slots
        Route::get('/{teacherId}/availability',         [TeacherAvailabilityCtrl::class, 'index']);
        Route::post('/{teacherId}/availability',        [TeacherAvailabilityCtrl::class, 'store']);
        Route::put('/{teacherId}/availability/{id}',    [TeacherAvailabilityCtrl::class, 'update']);
        Route::delete('/{teacherId}/availability/{id}', [TeacherAvailabilityCtrl::class, 'destroy']);
    });

    /*
    |--------------------------------------------------------------------------
    | Student Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:student')->prefix('student')->group(function () {

        // Profile
        Route::get('/{studentId}/profile', [StudentProfileController::class, 'show']);

        // Homework — view assigned homework
        Route::get('/{studentId}/homework',      [StudentHomeworkController::class, 'index']);
        Route::get('/{studentId}/homework/{id}', [StudentHomeworkController::class, 'show']);

        // Homework submissions
        Route::get('/{studentId}/submissions',      [StudentSubmissionController::class, 'index']);
        Route::post('/{studentId}/submissions',     [StudentSubmissionController::class, 'store']);
        Route::get('/{studentId}/submissions/{id}', [StudentSubmissionController::class, 'show']);

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

        // Assessment Calendar — upcoming exams/assessments for student's section
        Route::get('/{studentId}/assessment-calendar', [AssessmentCalendarController::class, 'studentCalendar']);

        // Bus — assignment, live location, boarding history
        Route::get('/{studentId}/bus/assignment',    [StudentBusController::class, 'assignment']);
        Route::get('/{studentId}/bus/live-location', [StudentBusController::class, 'liveLocation']);
        Route::get('/{studentId}/bus/events',        [StudentBusController::class, 'events']);
    });

    /*
    |--------------------------------------------------------------------------
    | Parent Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:parent')->prefix('parent')->group(function () {

        // Profile
        Route::get('/{parentId}/profile', [ParentProfileController::class, 'show']);

        // Children list
        Route::get('/{parentId}/children', [ChildrenController::class, 'index']);

        // Child's marks
        Route::get('/{parentId}/children/{studentId}/marks',         [ChildMarksController::class, 'index']);
        Route::get('/{parentId}/children/{studentId}/marks/summary', [ChildMarksController::class, 'summary']);

        // Child's homework
        Route::get('/{parentId}/children/{studentId}/homework', [ChildHomeworkController::class, 'index']);

        // Child's schedule
        Route::get('/{parentId}/children/{studentId}/schedule', [ChildScheduleController::class, 'index']);

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

        // Invoices — view invoices for linked children
        Route::get('/{parentId}/invoices',      [ParentInvoiceController::class, 'index']);
        Route::get('/{parentId}/invoices/{id}', [ParentInvoiceController::class, 'show']);

        // Payments — view own payment history
        Route::get('/{parentId}/payments',      [ParentPaymentController::class, 'index']);
        Route::get('/{parentId}/payments/{id}', [ParentPaymentController::class, 'show']);

        // Stripe — online payment checkout
        Route::post('/{parentId}/payments/checkout',                     [StripeController::class, 'checkout']);
        Route::get('/{parentId}/payments/checkout/{sessionId}/status',   [StripeController::class, 'status']);

        // Child's assessment calendar
        Route::get('/{parentId}/children/{studentId}/assessment-calendar', [AssessmentCalendarController::class, 'parentCalendar']);

        // Child bus tracking
        Route::get('/{parentId}/children/{studentId}/bus/assignment',    [ChildBusController::class, 'assignment']);
        Route::get('/{parentId}/children/{studentId}/bus/live-location', [ChildBusController::class, 'liveLocation']);
        Route::get('/{parentId}/children/{studentId}/bus/events',        [ChildBusController::class, 'events']);
    });

    /*
    |--------------------------------------------------------------------------
    | Driver Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:driver')->prefix('driver')->group(function () {

        // Profile — driver info + assigned bus + routes driven
        Route::get('/{driverId}/profile', [DriverProfileController::class, 'show']);

        // Trips
        Route::get('/{driverId}/trips',          [DriverTripController::class, 'index']);
        Route::get('/{driverId}/trips/today',    [DriverTripController::class, 'today']);
        Route::get('/{driverId}/trips/{tripId}', [DriverTripController::class, 'show']);

        // GPS pings (live tracking)
        Route::post('/{driverId}/trips/{tripId}/pings', [DriverTrackingController::class, 'store']);

        // Stop events (boarding / drop-off button)
        Route::get('/{driverId}/trips/{tripId}/stop-events',  [DriverStopEventController::class, 'index']);
        Route::post('/{driverId}/trips/{tripId}/stop-events', [DriverStopEventController::class, 'store']);
    });

    /*
    |--------------------------------------------------------------------------
    | AI Module Routes (authenticated service account)
    |--------------------------------------------------------------------------
    */
    Route::prefix('ai')->group(function () {
        Route::post('/surveillance-events', [AiSurveillanceController::class, 'store']);
    });
});
