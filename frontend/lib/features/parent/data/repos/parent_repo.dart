import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';

/// Handles both raw `[...]` and paginated `{"data":[...]}` responses.
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

  // ── Profile / children ─────────────────────────────────────────────────────

  Future<ParentProfileModel> getProfile() async {
    final res = await api.getApi(AppUrl.parentProfile(parentId));
    return ParentProfileModel.fromJson(res as Map<String, dynamic>);
  }

  /// Richer per-child info (relationship, enrollment, ...). Backend returns
  /// `{ total_children, children: [...] }`.
  Future<List<ChildDetailModel>> getChildren() async {
    final res = await api.getApi(AppUrl.parentChildren(parentId));
    final map = res as Map<String, dynamic>;
    return (map['children'] as List<dynamic>? ?? const [])
        .map((c) => ChildDetailModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ── Per-child academic data ────────────────────────────────────────────────

  Future<List<ParentAssessmentModel>> getChildMarks(int childId) async {
    final res = await api.getApi(AppUrl.parentChildMarks(parentId, childId));
    return _toList(res)
        .map((m) => ParentAssessmentModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Optional — backend also exposes a per-subject summary endpoint.
  Future<Map<String, dynamic>> getChildMarksSummary(int childId) async {
    final res = await api
        .getApi(AppUrl.parentChildMarksSummary(parentId, childId));
    return res as Map<String, dynamic>;
  }

  Future<ParentAttendanceSummaryModel> getChildAttendance(int childId) async {
    final res =
        await api.getApi(AppUrl.parentChildAttendance(parentId, childId));
    return ParentAttendanceSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ParentHomeworkModel>> getChildHomework(int childId) async {
    final res = await api.getApi(AppUrl.parentChildHomework(parentId, childId));
    return _toList(res)
        .map((h) => ParentHomeworkModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParentScheduleSlotModel>> getChildSchedule(int childId) async {
    final res = await api.getApi(AppUrl.parentChildSchedule(parentId, childId));
    return _toList(res)
        .map((s) =>
            ParentScheduleSlotModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Behavior = warning-channel notifications about a child.
  /// Backend returns a paginated `NotificationRecipient` list; we surface the
  /// underlying notifications as [ParentNotificationModel] with isWarning=true.
  Future<List<ParentNotificationModel>> getChildBehavior(int childId) async {
    final res = await api.getApi(AppUrl.parentChildBehavior(parentId, childId));
    final items = _toList(res);
    return items.map<ParentNotificationModel>((raw) {
      final recipient = raw as Map<String, dynamic>;
      // Each recipient row has a nested `notification` — prefer that shape,
      // fall back to the recipient row itself.
      final notif = recipient['notification'] as Map<String, dynamic>? ?? recipient;
      return ParentNotificationModel.fromJson(
        {
          'id': (notif['id'] ?? notif['notification_id'] ?? recipient['recipient_id']) as int,
          'title': notif['title'] ?? notif['channel'] ?? 'Warning',
          'body': notif['body'] ?? notif['message'],
          'is_read': recipient['status'] == 'read',
          'created_at': notif['created_at'] ?? recipient['created_at'] ?? '',
        },
        isWarning: true,
      );
    }).toList();
  }

  /// Per-child assessment calendar (upcoming quizzes/exams).
  Future<List<Map<String, dynamic>>> getChildAssessmentCalendar(int childId) async {
    final res = await api
        .getApi(AppUrl.parentChildAssessmentCalendar(parentId, childId));
    return _toList(res).whereType<Map<String, dynamic>>().toList();
  }

  // ── Bus (three endpoints) ──────────────────────────────────────────────────

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

  Future<List<BusEventModel>> getChildBusEvents(int childId) async {
    final res = await api.getApi(
        AppUrl.parentChildBusEvents(parentId, childId));
    return _toList(res)
        .map((e) => BusEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── School notes (backend calls them "notes", we surface as notifications)─

  Future<List<ParentNotificationModel>> getNotes() async {
    final res = await api.getApi(AppUrl.parentNotes(parentId));
    return _toList(res)
        .map((n) =>
            ParentNotificationModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  /// recipientId = NotificationRecipient.recipient_id from the notes list.
  Future<void> markNoteRead(int recipientId) async {
    await api.put(AppUrl.parentMarkNoteRead(parentId, recipientId));
  }

  // ── Messages (teacher ↔ parent) ────────────────────────────────────────────

  Future<List<MessageModel>> getMessages({int? page, int? perPage}) async {
    final res = await api.getApi(
      AppUrl.parentMessages(parentId),
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
    );
    return _toList(res)
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> getMessage(int messageId) async {
    final res = await api.getApi(AppUrl.parentMessage(parentId, messageId));
    return MessageModel.fromJson(res as Map<String, dynamic>);
  }

  Future<MessageModel> sendMessage({
    required int teacherId,
    int? studentId,
    required String subject,
    required String body,
  }) async {
    final res = await api.post(
      AppUrl.parentMessages(parentId),
      data: {
        'teacher_id': teacherId,
        if (studentId != null) 'student_id': studentId,
        'subject': subject,
        'body': body,
      },
    );
    return MessageModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Complaints ─────────────────────────────────────────────────────────────

  Future<List<ComplaintModel>> getComplaints({String? status}) async {
    final res = await api.getApi(
      AppUrl.parentComplaints(parentId),
      queryParameters: {if (status != null) 'status': status},
    );
    return _toList(res)
        .map((c) => ComplaintModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ComplaintModel> getComplaint(int complaintId) async {
    final res =
        await api.getApi(AppUrl.parentComplaint(parentId, complaintId));
    return ComplaintModel.fromJson(res as Map<String, dynamic>);
  }

  Future<ComplaintModel> submitComplaint({
    int? studentId,
    required String subject,
    required String body,
  }) async {
    final res = await api.post(
      AppUrl.parentComplaints(parentId),
      data: {
        if (studentId != null) 'student_id': studentId,
        'subject': subject,
        'body': body,
      },
    );
    return ComplaintModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Invoices ───────────────────────────────────────────────────────────────

  Future<InvoicesSummaryModel> getInvoices({int? studentId, String? status}) async {
    final res = await api.getApi(
      AppUrl.parentInvoices(parentId),
      queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (status != null) 'status': status,
      },
    );
    return InvoicesSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  /// Returns the raw invoice detail map — nested structure is verbose and
  /// UI-specific, so we keep it as a Map here rather than modelling every
  /// subfield.
  Future<Map<String, dynamic>> getInvoice(int invoiceId) async {
    final res = await api.getApi(AppUrl.parentInvoice(parentId, invoiceId));
    return res as Map<String, dynamic>;
  }

  // ── Payments history ───────────────────────────────────────────────────────

  Future<PaymentsHistoryModel> getPayments({
    int? studentId,
    String? method,
    String? paidFrom,
    String? paidTo,
  }) async {
    final res = await api.getApi(
      AppUrl.parentPayments(parentId),
      queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (method != null) 'method': method,
        if (paidFrom != null) 'paid_from': paidFrom,
        if (paidTo != null) 'paid_to': paidTo,
      },
    );
    return PaymentsHistoryModel.fromJson(res as Map<String, dynamic>);
  }

  Future<PaymentModel> getPayment(int paymentId) async {
    final res = await api.getApi(AppUrl.parentPayment(parentId, paymentId));
    return PaymentModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Stripe checkout ────────────────────────────────────────────────────────

  /// POST /payments/checkout — backend returns { checkout_url, session_id, amount }.
  /// Open [CheckoutSessionModel.checkoutUrl] externally, then poll
  /// [getCheckoutStatus] until `isTerminal`.
  Future<CheckoutSessionModel> createCheckout({
    required int invoiceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final res = await api.post(
      AppUrl.parentCheckout(parentId),
      data: {
        'invoice_id': invoiceId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
    );
    return CheckoutSessionModel.fromJson(res as Map<String, dynamic>);
  }

  Future<CheckoutStatusModel> getCheckoutStatus(String sessionId) async {
    final res =
        await api.getApi(AppUrl.parentCheckoutStatus(parentId, sessionId));
    return CheckoutStatusModel.fromJson(res as Map<String, dynamic>);
  }
}
