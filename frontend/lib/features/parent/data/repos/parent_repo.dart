import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';

List<dynamic> _toList(dynamic res) {
  if (res is List<dynamic>) return res;
  if (res is Map<String, dynamic>) {
    final data = res['data'];
    if (data is List<dynamic>) return data;
  }
  return const [];
}

class ParentRepo {
  final ApiConsumer api;
  final int parentId;

  ParentRepo({required this.api, required this.parentId});

  Future<ParentProfileModel> getProfile() async {
    final res = await api.getApi(AppUrl.parentProfile(parentId));
    return ParentProfileModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ParentAssessmentModel>> getChildMarks(int childId) async {
    final res =
        await api.getApi(AppUrl.parentChildMarks(parentId, childId));
    return _toList(res)
        .map((m) => ParentAssessmentModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<ParentAttendanceSummaryModel> getChildAttendance(int childId) async {
    final res =
        await api.getApi(AppUrl.parentChildAttendance(parentId, childId));
    return ParentAttendanceSummaryModel.fromJson(
        res as Map<String, dynamic>);
  }

  Future<List<ParentHomeworkModel>> getChildHomework(int childId) async {
    final res =
        await api.getApi(AppUrl.parentChildHomework(parentId, childId));
    return _toList(res)
        .map((h) => ParentHomeworkModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParentScheduleSlotModel>> getChildSchedule(int childId) async {
    final res =
        await api.getApi(AppUrl.parentChildSchedule(parentId, childId));
    return _toList(res)
        .map((s) =>
            ParentScheduleSlotModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // Bus — three separate endpoints per the backend.
  Future<ParentBusModel> getChildBusAssignment(int childId) async {
    final res =
        await api.getApi(AppUrl.parentChildBusAssignment(parentId, childId));
    return ParentBusModel.fromJson(res as Map<String, dynamic>);
  }

  Future<ParentBusModel> getChildBusLiveLocation(int childId) async {
    final res = await api.getApi(
        AppUrl.parentChildBusLiveLocation(parentId, childId));
    return ParentBusModel.fromJson(res as Map<String, dynamic>);
  }

  // Backend returns "school notes" (notifications) — NOT a /notifications path.
  // Warnings (behavior) live under /children/{id}/behavior, not a separate endpoint.
  Future<List<ParentNotificationModel>> getNotes() async {
    final res = await api.getApi(AppUrl.parentNotes(parentId));
    return _toList(res)
        .map((n) =>
            ParentNotificationModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  // recipientId = NotificationRecipient.recipient_id from the notes list
  Future<void> markNoteRead(int recipientId) async {
    await api.put(AppUrl.parentMarkNoteRead(parentId, recipientId));
  }
}
