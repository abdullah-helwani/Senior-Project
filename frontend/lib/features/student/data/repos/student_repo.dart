import 'package:dio/dio.dart';
import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/models/assessment_event_model.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

/// Handles both raw `[...]` and paginated `{"data":[...]}` responses.
List<dynamic> _toList(dynamic res) {
  if (res is List<dynamic>) return res;
  if (res is Map<String, dynamic>) {
    final data = res['data'];
    if (data is List<dynamic>) return data;
  }
  return const [];
}

class StudentRepo {
  final ApiConsumer api;
  final int studentId;

  StudentRepo({required this.api, required this.studentId});

  // No dedicated dashboard endpoint — cubits that need overview data call getProfile().
  Future<StudentProfileModel> getProfile() async {
    final res = await api.getApi(AppUrl.studentProfile(studentId));
    return StudentProfileModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<AssessmentModel>> getMarks() async {
    final res = await api.getApi(AppUrl.studentMarks(studentId));
    return _toList(res)
        .map((m) => AssessmentModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<MarksSummaryModel> getMarksSummary() async {
    final res = await api.getApi(AppUrl.studentMarksSummary(studentId));
    return MarksSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ScheduleSlotModel>> getSchedule() async {
    final res = await api.getApi(AppUrl.studentSchedule(studentId));
    return _toList(res)
        .map((s) => ScheduleSlotModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<AssessmentEventModel>> getAssessmentCalendar() async {
    final res = await api.getApi(AppUrl.studentAssessmentCalendar(studentId));
    return AssessmentEventModel.listFromResponse(res);
  }

  Future<List<HomeworkModel>> getHomework() async {
    final res = await api.getApi(AppUrl.studentHomework(studentId));
    return _toList(res)
        .map((h) => HomeworkModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  Future<HomeworkModel> getHomeworkDetail(int hwId) async {
    final res = await api.getApi(AppUrl.studentHomeworkItem(studentId, hwId));
    return HomeworkModel.fromJson(res as Map<String, dynamic>);
  }

  // POST /student/{id}/submissions — multipart {homework_id, file?}
  /// Submits homework with an optional file attachment.
  ///
  /// On web, [filePath] should be the picked file's bytes wrapped via the
  /// caller (we accept either a path or pre-built [MultipartFile]). For
  /// mobile, a plain path is fine.
  Future<void> submitHomework({
    required int hwId,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final form = <String, dynamic>{'homework_id': hwId};
    if (fileBytes != null) {
      form['file'] = MultipartFile.fromBytes(fileBytes, filename: fileName);
    } else if (filePath != null) {
      form['file'] = await MultipartFile.fromFile(filePath, filename: fileName);
    }
    await api.post(
      AppUrl.studentSubmissions(studentId),
      data: FormData.fromMap(form),
    );
  }

  Future<AttendanceSummaryModel> getAttendance() async {
    final res = await api.getApi(AppUrl.studentAttendance(studentId));
    return AttendanceSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<NotificationModel>> getNotifications() async {
    final res = await api.getApi(AppUrl.studentNotifications(studentId));
    return _toList(res)
        .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  // recipientId = NotificationRecipient.recipient_id (NOT the notification id)
  Future<void> markNotificationRead(int recipientId) async {
    await api.put(AppUrl.studentMarkNotificationRead(studentId, recipientId));
  }

  Future<void> markAllNotificationsRead() async {
    await api.put(AppUrl.studentMarkAllNotificationsRead(studentId));
  }

  Future<List<NotificationModel>> getWarnings() async {
    final res = await api.getApi(AppUrl.studentWarnings(studentId));
    return _toList(res)
        .map((n) => NotificationModel.fromJson(
              n as Map<String, dynamic>,
              isWarning: true,
            ))
        .toList();
  }

  Future<BusAssignmentModel> getBusAssignment() async {
    final res = await api.getApi(AppUrl.studentBusAssignment(studentId));
    return BusAssignmentModel.fromJson(res as Map<String, dynamic>);
  }

  Future<BusLiveLocationModel> getBusLiveLocation() async {
    final res = await api.getApi(AppUrl.studentBusLive(studentId));
    return BusLiveLocationModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<BusEventModel>> getBusEvents() async {
    final res = await api.getApi(AppUrl.studentBusEvents(studentId));
    return _toList(res)
        .map((e) => BusEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
