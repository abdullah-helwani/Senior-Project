// ─── Backend host ─────────────────────────────────────────────────────────────
// Start backend with: php artisan serve   (binds to 127.0.0.1:8000)
//
// Then pick the right value below for your device:
//   Chrome / web      →  'http://localhost:8000'  (or 'http://127.0.0.1:8000')
//   Android emulator  →  'http://10.0.2.2:8000'
//   iOS simulator     →  'http://127.0.0.1:8000'
//   Physical device   →  'http://192.168.x.x:8000'  ← run `ipconfig` to find your PC's LAN IP
//                         (both PC and phone must be on the same Wi-Fi)
const String baseUrl = 'http://localhost:8000';   // ← change this to match your setup

const String _api = '$baseUrl/api';

// ─── Endpoints ────────────────────────────────────────────────────────────────

class AppUrl {
  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String login          = '$_api/login';
  static const String logout         = '$_api/logout';
  static const String me             = '$_api/me';
  static const String changePassword = '$_api/change-password';          // PUT
  static const String profilePicture = '$_api/profile-picture';          // POST / DELETE

  // ── Driver ──────────────────────────────────────────────────────────────────
  static String driverProfile(int id)  => '$_api/driver/$id/profile';
  static String driverTrips(int id)    => '$_api/driver/$id/trips';
  static String driverTripsToday(int id) => '$_api/driver/$id/trips/today';
  static String driverTrip(int id, int tripId) =>
      '$_api/driver/$id/trips/$tripId';
  static String driverPings(int id, int tripId) =>
      '$_api/driver/$id/trips/$tripId/pings';
  static String driverStopEvents(int id, int tripId) =>
      '$_api/driver/$id/trips/$tripId/stop-events';

  // ── Student ─────────────────────────────────────────────────────────────────
  // Note: no dedicated /dashboard endpoint — profile is the entry point.
  static String studentProfile(int id)      => '$_api/student/$id/profile';
  static String studentMarks(int id)        => '$_api/student/$id/marks';
  static String studentMarksSummary(int id) => '$_api/student/$id/marks/summary';
  static String studentSchedule(int id)     => '$_api/student/$id/schedule';
  static String studentHomework(int id)     => '$_api/student/$id/homework';
  static String studentHomeworkItem(int id, int hwId) =>
      '$_api/student/$id/homework/$hwId';
  // Submissions are a separate resource (POST multipart {homework_id, file?})
  static String studentSubmissions(int id)  => '$_api/student/$id/submissions';
  static String studentAttendance(int id)   => '$_api/student/$id/attendance';
  static String studentWarnings(int id)     => '$_api/student/$id/warnings';
  static String studentNotifications(int id)  => '$_api/student/$id/notifications';
  // recipientId — use the NotificationRecipient id, not the Notification id
  static String studentMarkNotificationRead(int id, int recipientId) =>
      '$_api/student/$id/notifications/$recipientId/read';           // PUT
  static String studentMarkAllNotificationsRead(int id) =>
      '$_api/student/$id/notifications/read-all';                    // PUT
  static String studentAssessmentCalendar(int id) =>
      '$_api/student/$id/assessment-calendar';
  static String studentBusAssignment(int id) =>
      '$_api/student/$id/bus/assignment';
  static String studentBusLive(int id)      =>
      '$_api/student/$id/bus/live-location';
  static String studentBusEvents(int id)    => '$_api/student/$id/bus/events';

  // ── Teacher ─────────────────────────────────────────────────────────────────
  // Note: no /dashboard or /classes endpoint.
  // Teacher classes come from the /profile response (assignments field).
  static String teacherProfile(int id)     => '$_api/teacher/$id/profile';
  static String teacherNotifications(int id) => '$_api/teacher/$id/notifications';
  static String teacherMarkNotificationRead(int id, int recipientId) =>
      '$_api/teacher/$id/notifications/$recipientId/read';
  static String teacherMarkAllNotificationsRead(int id) =>
      '$_api/teacher/$id/notifications/read-all';
  static String teacherSchedule(int id)    => '$_api/teacher/$id/schedule';
  // Homework CRUD — GET list / POST new / GET one / PUT update / DELETE
  static String teacherHomework(int id)    => '$_api/teacher/$id/homework';
  static String teacherHomeworkItem(int id, int hwId) =>
      '$_api/teacher/$id/homework/$hwId';
  // Returns { homework, summary, submissions: [...] }
  static String teacherHomeworkSubmissions(int id, int hwId) =>
      '$_api/teacher/$id/homework/$hwId/submissions';
  // PUT — body: { score }  (field name is "score", NOT "grade")
  static String teacherGradeSubmission(int id, int hwId, int subId) =>
      '$_api/teacher/$id/homework/$hwId/submissions/$subId/grade';
  // POST to create session + records in one call: { section_id, date, records:[...] }
  // GET  with ?section_id (required), ?date
  static String teacherAttendance(int id)  => '$_api/teacher/$id/attendance';
  static String teacherAssessmentCalendar(int id) =>
      '$_api/teacher/$id/assessment-calendar';
  // Messages — sent list / inbox / send / show
  static String teacherMessages(int id)      => '$_api/teacher/$id/messages';
  static String teacherMessagesInbox(int id) => '$_api/teacher/$id/messages/inbox';
  static String teacherMessage(int id, int msgId) =>
      '$_api/teacher/$id/messages/$msgId';
  // Performance report — requires ?section_id ; optional ?subject_id ?week_of
  static String teacherPerformanceReport(int id) =>
      '$_api/teacher/$id/performance-report';
  // Behavior logs — list / create / show
  static String teacherBehaviorLogs(int id) =>
      '$_api/teacher/$id/behavior-logs';
  static String teacherBehaviorLog(int id, int logId) =>
      '$_api/teacher/$id/behavior-logs/$logId';
  // Salary
  static String teacherSalary(int id)              => '$_api/teacher/$id/salary';
  static String teacherSalaryItem(int id, int salId) =>
      '$_api/teacher/$id/salary/$salId';
  // Vacation requests
  static String teacherVacationRequests(int id) =>
      '$_api/teacher/$id/vacation-requests';
  static String teacherVacationRequest(int id, int reqId) =>
      '$_api/teacher/$id/vacation-requests/$reqId';
  // Availability — GET/POST on list ; PUT/DELETE on item
  static String teacherAvailability(int id)      => '$_api/teacher/$id/availability';
  static String teacherAvailabilityItem(int id, int slotId) =>
      '$_api/teacher/$id/availability/$slotId';

  // ── Parent ──────────────────────────────────────────────────────────────────
  static String parentProfile(int id)     => '$_api/parent/$id/profile';
  // Richer per-child info than what profile.children carries (enrollment, relationship, ...)
  static String parentChildren(int id)    => '$_api/parent/$id/children';
  static String parentChildMarks(int id, int childId) =>
      '$_api/parent/$id/children/$childId/marks';
  static String parentChildMarksSummary(int id, int childId) =>
      '$_api/parent/$id/children/$childId/marks/summary';
  static String parentChildAttendance(int id, int childId) =>
      '$_api/parent/$id/children/$childId/attendance';
  static String parentChildHomework(int id, int childId) =>
      '$_api/parent/$id/children/$childId/homework';
  static String parentChildSchedule(int id, int childId) =>
      '$_api/parent/$id/children/$childId/schedule';
  static String parentChildBehavior(int id, int childId) =>
      '$_api/parent/$id/children/$childId/behavior';
  static String parentChildAssessmentCalendar(int id, int childId) =>
      '$_api/parent/$id/children/$childId/assessment-calendar';
  // Bus — three separate endpoints per the backend
  static String parentChildBusAssignment(int id, int childId) =>
      '$_api/parent/$id/children/$childId/bus/assignment';
  static String parentChildBusLiveLocation(int id, int childId) =>
      '$_api/parent/$id/children/$childId/bus/live-location';
  static String parentChildBusEvents(int id, int childId) =>
      '$_api/parent/$id/children/$childId/bus/events';
  // Notes = school notifications (backend calls them /notes, not /notifications)
  // Warnings (behavior) live under /children/{id}/behavior — no separate /warnings
  static String parentNotes(int id)       => '$_api/parent/$id/notes';
  // recipientId — the NotificationRecipient id returned in the notes list
  static String parentMarkNoteRead(int id, int recipientId) =>
      '$_api/parent/$id/notes/$recipientId/read';                    // PUT
  static String parentMessages(int id)    => '$_api/parent/$id/messages';
  static String parentMessage(int id, int messageId) =>
      '$_api/parent/$id/messages/$messageId';
  static String parentComplaints(int id)  => '$_api/parent/$id/complaints';
  static String parentComplaint(int id, int complaintId) =>
      '$_api/parent/$id/complaints/$complaintId';
  static String parentInvoices(int id)    => '$_api/parent/$id/invoices';
  static String parentInvoice(int id, int invoiceId) =>
      '$_api/parent/$id/invoices/$invoiceId';
  static String parentPayments(int id)    => '$_api/parent/$id/payments';
  static String parentPayment(int id, int paymentId) =>
      '$_api/parent/$id/payments/$paymentId';
  // Stripe
  static String parentCheckout(int id)    => '$_api/parent/$id/payments/checkout';
  static String parentCheckoutStatus(int id, String sessionId) =>
      '$_api/parent/$id/payments/checkout/$sessionId/status';
}

// ─── Local-storage keys ───────────────────────────────────────────────────────

class CacheKey {
  static const String token = 'auth_token';
  static const String user  = 'auth_user';
}
