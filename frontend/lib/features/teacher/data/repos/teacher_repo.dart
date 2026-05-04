import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/models/assessment_event_model.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

List<dynamic> _toList(dynamic res) {
  if (res is List<dynamic>) return res;
  if (res is Map<String, dynamic>) {
    final data = res['data'];
    if (data is List<dynamic>) return data;
  }
  return const [];
}

class TeacherRepo {
  final ApiConsumer api;
  final int teacherId;

  TeacherRepo({required this.api, required this.teacherId});

  // ── Profile / classes / schedule ───────────────────────────────────────────
  // /profile returns the full teacher object including assignments (classes).
  // There is no separate /dashboard or /classes endpoint.
  Future<TeacherProfileModel> getProfile() async {
    final res = await api.getApi(AppUrl.teacherProfile(teacherId));
    return TeacherProfileModel.fromJson(res as Map<String, dynamic>);
  }

  // Teacher classes are embedded in the profile response (assignments field).
  Future<List<TeacherClassModel>> getClasses() async {
    final res = await api.getApi(AppUrl.teacherProfile(teacherId));
    final assignments =
        (res as Map<String, dynamic>)['assignments'] as List<dynamic>? ?? [];
    return assignments
        .map((c) => TeacherClassModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeacherScheduleSlotModel>> getSchedule() async {
    final res = await api.getApi(AppUrl.teacherSchedule(teacherId));
    return _toList(res)
        .map((s) => TeacherScheduleSlotModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // ── Homework CRUD ──────────────────────────────────────────────────────────

  Future<List<TeacherHomeworkModel>> getHomework({
    int? subjectId,
    int? sectionId,
  }) async {
    final res = await api.getApi(
      AppUrl.teacherHomework(teacherId),
      queryParameters: {
        if (subjectId != null) 'subject_id': subjectId,
        if (sectionId != null) 'section_id': sectionId,
      },
    );
    return _toList(res)
        .map((h) => TeacherHomeworkModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  /// Returns the raw homework detail map — nested relations vary, UI can
  /// pluck what it needs.
  Future<Map<String, dynamic>> getHomeworkDetail(int hwId) async {
    final res = await api.getApi(AppUrl.teacherHomeworkItem(teacherId, hwId));
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createHomework({
    required int subjectId,
    required int sectionId,
    required String title,
    String? description,
    required String dueDate, // YYYY-MM-DD (must be after today per backend)
  }) async {
    final res = await api.post(
      AppUrl.teacherHomework(teacherId),
      data: {
        'subject_id': subjectId,
        'section_id': sectionId,
        'title': title,
        if (description != null) 'description': description,
        'due_date': dueDate,
      },
    );
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateHomework(
    int hwId, {
    String? title,
    String? description,
    String? dueDate,
  }) async {
    final res = await api.put(
      AppUrl.teacherHomeworkItem(teacherId, hwId),
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'due_date': dueDate,
      },
    );
    return res as Map<String, dynamic>;
  }

  Future<void> deleteHomework(int hwId) async {
    await api.delete(AppUrl.teacherHomeworkItem(teacherId, hwId));
  }

  // ── Submissions ────────────────────────────────────────────────────────────

  /// Legacy list-only accessor. Prefer [getSubmissionsDetail].
  Future<List<HomeworkSubmissionModel>> getSubmissions(int hwId) async {
    final res = await api.getApi(
      AppUrl.teacherHomeworkSubmissions(teacherId, hwId),
    );
    // Backend shape: { homework, summary, submissions: [...] }. Fall back to
    // raw list / paginator shapes for robustness.
    final list = res is Map<String, dynamic>
        ? (res['submissions'] is List
            ? res['submissions'] as List<dynamic>
            : _toList(res))
        : _toList(res);
    return list
        .map((s) => HomeworkSubmissionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Full response: summary + submissions. The UI can render the header stats
  /// (total enrolled, submitted, graded, not submitted, average score).
  Future<({SubmissionsSummaryModel summary, List<HomeworkSubmissionModel> submissions})>
      getSubmissionsDetail(int hwId, {String? status}) async {
    final res = await api.getApi(
      AppUrl.teacherHomeworkSubmissions(teacherId, hwId),
      queryParameters: {if (status != null) 'status': status},
    );
    final map = res as Map<String, dynamic>;
    final summary = SubmissionsSummaryModel.fromJson(
      (map['summary'] as Map<String, dynamic>?) ?? const {},
    );
    final raw = (map['submissions'] as List<dynamic>?) ?? const [];
    final submissions = raw
        .map((s) => HomeworkSubmissionModel.fromJson(s as Map<String, dynamic>))
        .toList();
    return (summary: summary, submissions: submissions);
  }

  // PUT — body field is "score" (not "grade")
  Future<void> gradeSubmission({
    required int hwId,
    required int submissionId,
    required double grade,
    String? feedback,
  }) async {
    await api.put(
      AppUrl.teacherGradeSubmission(teacherId, hwId, submissionId),
      data: {
        'score': grade,
        if (feedback != null) 'feedback': feedback,
      },
    );
  }

  // ── Attendance ─────────────────────────────────────────────────────────────

  /// GET /attendance?section_id=...&date=...
  /// section_id is **required** by the backend — the existing callers in the
  /// attendance cubit pass it via the overload below. This no-arg version is
  /// preserved for backwards compatibility and will only work if the backend
  /// tolerates a missing filter (it 422s otherwise).
  Future<List<TeacherAttendanceSessionModel>> getAttendanceSessions({
    int? sectionId,
    String? date,
  }) async {
    final res = await api.getApi(
      AppUrl.teacherAttendance(teacherId),
      queryParameters: {
        if (sectionId != null) 'section_id': sectionId,
        if (date != null) 'date': date,
      },
    );
    return _toList(res)
        .map((s) =>
            TeacherAttendanceSessionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // POST attendance — creates session + records in one call.
  Future<void> submitAttendance({
    required int sectionId,
    required String date,
    required List<AttendanceEntryModel> entries,
  }) async {
    await api.post(
      AppUrl.teacherAttendance(teacherId),
      data: {
        'section_id': sectionId,
        'date': date,
        'records': entries
            .map((e) => {'student_id': e.studentId, 'status': e.status})
            .toList(),
      },
    );
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<TeacherMessageModel>> getSentMessages({
    int? receiverId,
    int? studentId,
    int? page,
  }) async {
    final res = await api.getApi(
      AppUrl.teacherMessages(teacherId),
      queryParameters: {
        if (receiverId != null) 'receiver_id': receiverId,
        if (studentId != null) 'student_id': studentId,
        if (page != null) 'page': page,
      },
    );
    return _toList(res)
        .map((m) => TeacherMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherInboxModel> getInbox({
    int? senderId,
    int? studentId,
    bool unreadOnly = false,
    int? page,
  }) async {
    final res = await api.getApi(
      AppUrl.teacherMessagesInbox(teacherId),
      queryParameters: {
        if (senderId != null) 'sender_id': senderId,
        if (studentId != null) 'student_id': studentId,
        if (unreadOnly) 'unread': 'true',
        if (page != null) 'page': page,
      },
    );
    return TeacherInboxModel.fromJson(res as Map<String, dynamic>);
  }

  Future<TeacherMessageModel> getMessage(int messageId) async {
    final res = await api.getApi(AppUrl.teacherMessage(teacherId, messageId));
    return TeacherMessageModel.fromJson(res as Map<String, dynamic>);
  }

  /// Teacher → parent. `receiverId` is the parent's **user_id**, not parent_id.
  Future<TeacherMessageModel> sendMessage({
    required int receiverUserId,
    int? studentId,
    String? subject,
    required String body,
  }) async {
    final res = await api.post(
      AppUrl.teacherMessages(teacherId),
      data: {
        'receiver_id': receiverUserId,
        if (studentId != null) 'student_id': studentId,
        if (subject != null) 'subject': subject,
        'body': body,
      },
    );
    return TeacherMessageModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Performance report ─────────────────────────────────────────────────────

  /// Weekly student performance for one section. `sectionId` is required by
  /// the backend. `weekOf` is any date within the target week (defaults to
  /// the current week server-side).
  Future<PerformanceReportModel> getPerformanceReport({
    required int sectionId,
    int? subjectId,
    String? weekOf,
  }) async {
    final res = await api.getApi(
      AppUrl.teacherPerformanceReport(teacherId),
      queryParameters: {
        'section_id': sectionId,
        if (subjectId != null) 'subject_id': subjectId,
        if (weekOf != null) 'week_of': weekOf,
      },
    );
    return PerformanceReportModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Behavior logs ──────────────────────────────────────────────────────────

  Future<List<BehaviorLogModel>> getBehaviorLogs({
    int? sectionId,
    int? studentId,
    String? type,
    String? from,
    String? to,
  }) async {
    final res = await api.getApi(
      AppUrl.teacherBehaviorLogs(teacherId),
      queryParameters: {
        if (sectionId != null) 'section_id': sectionId,
        if (studentId != null) 'student_id': studentId,
        if (type != null) 'type': type,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return _toList(res)
        .map((l) => BehaviorLogModel.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  Future<BehaviorLogModel> getBehaviorLog(int logId) async {
    final res = await api.getApi(AppUrl.teacherBehaviorLog(teacherId, logId));
    return BehaviorLogModel.fromJson(res as Map<String, dynamic>);
  }

  Future<BehaviorLogModel> createBehaviorLog({
    required int studentId,
    required int sectionId,
    required String type, // positive/negative/neutral
    required String title,
    String? description,
    required String date, // YYYY-MM-DD
    bool notifyParent = false,
  }) async {
    final res = await api.post(
      AppUrl.teacherBehaviorLogs(teacherId),
      data: {
        'student_id': studentId,
        'section_id': sectionId,
        'type': type,
        'title': title,
        if (description != null) 'description': description,
        'date': date,
        'notify_parent': notifyParent,
      },
    );
    return BehaviorLogModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Salary ─────────────────────────────────────────────────────────────────

  Future<SalarySummaryModel> getSalary({String? year}) async {
    final res = await api.getApi(
      AppUrl.teacherSalary(teacherId),
      queryParameters: {if (year != null) 'year': year},
    );
    return SalarySummaryModel.fromJson(res as Map<String, dynamic>);
  }

  Future<SalaryPaymentModel> getSalaryPayment(int salaryId) async {
    final res = await api.getApi(AppUrl.teacherSalaryItem(teacherId, salaryId));
    return SalaryPaymentModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Vacation requests ──────────────────────────────────────────────────────

  Future<List<VacationRequestModel>> getVacationRequests({String? status}) async {
    final res = await api.getApi(
      AppUrl.teacherVacationRequests(teacherId),
      queryParameters: {if (status != null) 'status': status},
    );
    // Shape: { teacher_id, count, requests: [...] }
    final map = res as Map<String, dynamic>;
    final raw = (map['requests'] as List<dynamic>?) ?? const [];
    return raw
        .map((r) => VacationRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<VacationRequestModel> getVacationRequest(int requestId) async {
    final res = await api
        .getApi(AppUrl.teacherVacationRequest(teacherId, requestId));
    return VacationRequestModel.fromJson(res as Map<String, dynamic>);
  }

  Future<VacationRequestModel> createVacationRequest({
    required String startDate,
    required String endDate,
  }) async {
    final res = await api.post(
      AppUrl.teacherVacationRequests(teacherId),
      data: {'start_date': startDate, 'end_date': endDate},
    );
    return VacationRequestModel.fromJson(res as Map<String, dynamic>);
  }

  /// Cancels a pending request (backend only deletes `status === 'pending'`).
  Future<void> cancelVacationRequest(int requestId) async {
    await api.delete(AppUrl.teacherVacationRequest(teacherId, requestId));
  }

  // ── Assessment calendar ────────────────────────────────────────────────────

  Future<List<AssessmentEventModel>> getAssessmentCalendar() async {
    final res = await api.getApi(AppUrl.teacherAssessmentCalendar(teacherId));
    return AssessmentEventModel.listFromResponse(res);
  }

  // ── Availability CRUD ─────────────────────────────────────────────────────

  Future<List<TeacherAvailabilityModel>> getAvailability({String? dayOfWeek}) async {
    final res = await api.getApi(
      AppUrl.teacherAvailability(teacherId),
      queryParameters: {if (dayOfWeek != null) 'dayofweek': dayOfWeek},
    );
    // Shape: { teacher_id, count, slots: [...] }
    final map = res as Map<String, dynamic>;
    final raw = (map['slots'] as List<dynamic>?) ?? const [];
    return raw
        .map((s) => TeacherAvailabilityModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherAvailabilityModel> createAvailability({
    required String dayOfWeek, // Monday..Sunday
    required String startTime, // HH:mm (24h)
    required String endTime,
    required String type,      // available/unavailable/preferred
  }) async {
    final res = await api.post(
      AppUrl.teacherAvailability(teacherId),
      data: {
        'dayofweek': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'availabilitytype': type,
      },
    );
    return TeacherAvailabilityModel.fromJson(res as Map<String, dynamic>);
  }

  Future<TeacherAvailabilityModel> updateAvailability(
    int slotId, {
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? type,
  }) async {
    final res = await api.put(
      AppUrl.teacherAvailabilityItem(teacherId, slotId),
      data: {
        if (dayOfWeek != null) 'dayofweek': dayOfWeek,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (type != null) 'availabilitytype': type,
      },
    );
    return TeacherAvailabilityModel.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteAvailability(int slotId) async {
    await api.delete(AppUrl.teacherAvailabilityItem(teacherId, slotId));
  }

  // ── Legacy stubs kept for existing cubits ──────────────────────────────────
  // Teacher notifications are not exposed by the backend.
  Future<List<TeacherNotificationModel>> getNotifications() async {
    throw UnimplementedError('Teacher notification endpoint not available');
  }

  Future<void> markNotificationRead(int notificationId) async {
    throw UnimplementedError('Teacher notification endpoint not available');
  }
}
