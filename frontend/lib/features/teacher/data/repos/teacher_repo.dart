import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/utils/app_url.dart';
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

  // /profile returns the full teacher object including assignments (classes).
  // There is no separate /dashboard or /classes endpoint.
  Future<TeacherProfileModel> getProfile() async {
    final res = await api.getApi(AppUrl.teacherProfile(teacherId));
    return TeacherProfileModel.fromJson(res as Map<String, dynamic>);
  }

  // Teacher classes are embedded in the profile response (assignments field).
  // This method exists for cubits that request classes separately;
  // it hits /profile and the cubit falls back to mock if the shape differs.
  Future<List<TeacherClassModel>> getClasses() async {
    final res = await api.getApi(AppUrl.teacherProfile(teacherId));
    final assignments = (res as Map<String, dynamic>)['assignments'] as List<dynamic>? ?? [];
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

  Future<List<TeacherHomeworkModel>> getHomework() async {
    final res = await api.getApi(AppUrl.teacherHomework(teacherId));
    return _toList(res)
        .map((h) => TeacherHomeworkModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  Future<List<HomeworkSubmissionModel>> getSubmissions(int hwId) async {
    final res = await api.getApi(
        AppUrl.teacherHomeworkSubmissions(teacherId, hwId));
    return _toList(res)
        .map((s) => HomeworkSubmissionModel.fromJson(s as Map<String, dynamic>))
        .toList();
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
        ...{if (feedback != null) 'feedback': feedback},
      },
    );
  }

  // GET attendance sessions for a section
  Future<List<TeacherAttendanceSessionModel>> getAttendanceSessions() async {
    final res = await api.getApi(AppUrl.teacherAttendance(teacherId));
    return _toList(res)
        .map((s) =>
            TeacherAttendanceSessionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // POST attendance — creates session + records in one call.
  // sectionId = the section's id (maps to session.id in our local model).
  // Body: { section_id, date, records: [{student_id, status}] }
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

  // Teacher notifications are not exposed by the backend.
  // These methods throw so the cubit always falls back to mock data.
  Future<List<TeacherNotificationModel>> getNotifications() async {
    throw UnimplementedError('Teacher notification endpoint not available');
  }

  Future<void> markNotificationRead(int notificationId) async {
    throw UnimplementedError('Teacher notification endpoint not available');
  }
}
