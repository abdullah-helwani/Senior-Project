import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChildDetailModel — richer per-child info from GET /parent/{id}/children
// Shape: { total_children, children: [ { student_id, name, relationship, ... } ] }
// ─────────────────────────────────────────────────────────────────────────────

class ChildDetailModel extends Equatable {
  final int studentId;
  final String name;
  final String? email;
  final String? dateOfBirth;
  final String? gender;
  final String? status;
  final String? relationship; // father/mother/guardian/...
  final bool isPrimary;

  // Enrollment (nullable if student isn't currently enrolled)
  final String? enrollmentSection;
  final String? enrollmentClass;
  final String? enrollmentSchoolYear;

  const ChildDetailModel({
    required this.studentId,
    required this.name,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.status,
    this.relationship,
    this.isPrimary = false,
    this.enrollmentSection,
    this.enrollmentClass,
    this.enrollmentSchoolYear,
  });

  factory ChildDetailModel.fromJson(Map<String, dynamic> json) {
    final enroll = json['current_enrollment'] as Map<String, dynamic>?;
    return ChildDetailModel(
      studentId: json['student_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      status: json['status'] as String?,
      relationship: json['relationship'] as String?,
      isPrimary: (json['isprimary'] as bool?) ?? false,
      enrollmentSection: enroll?['section'] as String?,
      enrollmentClass: enroll?['class'] as String?,
      enrollmentSchoolYear: enroll?['school_year'] as String?,
    );
  }

  @override
  List<Object?> get props => [studentId, name, relationship, isPrimary];
}

// ─────────────────────────────────────────────────────────────────────────────
// MessageModel — inbox items + detail
// Laravel paginates; list response wraps in { data: [...] }
// Item shape: { id, sender_id, receiver_id, student_id, subject, body,
//               read_at, created_at, sender:{...}, receiver:{...}, student:{...} }
// ─────────────────────────────────────────────────────────────────────────────

class MessageModel extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String? senderName;
  final String? receiverName;
  final int? studentId;
  final String? studentName;
  final String subject;
  final String body;
  final String? readAt;
  final String createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.senderName,
    this.receiverName,
    this.studentId,
    this.studentName,
    required this.subject,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  /// Whether *this* parent was the sender (vs. a teacher message to them).
  /// The caller passes the parent's own user_id.
  bool sentByMe(int myUserId) => senderId == myUserId;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final receiver = json['receiver'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final studentUser = student == null
        ? null
        : student['user'] as Map<String, dynamic>?;

    return MessageModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      senderName: sender?['name'] as String?,
      receiverName: receiver?['name'] as String?,
      studentId: json['student_id'] as int?,
      studentName: studentUser?['name'] as String?,
      subject: json['subject'] as String,
      body: json['body'] as String,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, subject, readAt, createdAt];
}

// ─────────────────────────────────────────────────────────────────────────────
// ComplaintModel
// Item shape: { complaint_id, parent_id, student_id, subject, body, status,
//               created_at, student:{ user:{ name } } }
// ─────────────────────────────────────────────────────────────────────────────

class ComplaintModel extends Equatable {
  final int id;
  final int? studentId;
  final String? studentName;
  final String subject;
  final String body;
  final String status; // pending / in_review / resolved / rejected
  final String createdAt;

  const ComplaintModel({
    required this.id,
    this.studentId,
    this.studentName,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final studentUser = student == null
        ? null
        : student['user'] as Map<String, dynamic>?;

    return ComplaintModel(
      id: (json['complaint_id'] ?? json['id']) as int,
      studentId: json['student_id'] as int?,
      studentName: studentUser?['name'] as String?,
      subject: json['subject'] as String,
      body: json['body'] as String,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, subject, status, createdAt];
}

// ─────────────────────────────────────────────────────────────────────────────
// InvoiceModel — list items are flattened/enriched by the backend:
// { invoice_id, student:{id,name}, fee_plan, school_year, due_date,
//   totalamount, paid_total, outstanding, status }
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceModel extends Equatable {
  final int id;
  final int? studentId;
  final String? studentName;
  final String? feePlan;
  final String? schoolYear;
  final String dueDate;
  final double totalAmount;
  final double paidTotal;
  final double outstanding;
  final String status; // pending / partially_paid / paid / overdue / cancelled

  const InvoiceModel({
    required this.id,
    this.studentId,
    this.studentName,
    this.feePlan,
    this.schoolYear,
    required this.dueDate,
    required this.totalAmount,
    required this.paidTotal,
    required this.outstanding,
    required this.status,
  });

  bool get isPayable => outstanding > 0 && status != 'paid' && status != 'cancelled';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    double n(dynamic v) =>
        v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

    return InvoiceModel(
      id: json['invoice_id'] as int,
      studentId: student?['id'] as int?,
      studentName: student?['name'] as String?,
      feePlan: json['fee_plan'] as String?,
      schoolYear: json['school_year'] as String?,
      dueDate: (json['due_date'] as String?) ?? '',
      totalAmount: n(json['totalamount']),
      paidTotal: n(json['paid_total']),
      outstanding: n(json['outstanding']),
      status: (json['status'] as String?) ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [id, dueDate, outstanding, status];
}

class InvoicesSummaryModel extends Equatable {
  final int total;
  final double outstanding;
  final List<InvoiceModel> invoices;

  const InvoicesSummaryModel({
    required this.total,
    required this.outstanding,
    required this.invoices,
  });

  factory InvoicesSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['invoices'] as List<dynamic>? ?? const [];
    final outstanding = json['outstanding'];
    return InvoicesSummaryModel(
      total: (json['total'] as int?) ?? raw.length,
      outstanding: outstanding is num ? outstanding.toDouble() : 0,
      invoices: raw
          .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [total, outstanding, invoices];
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentModel
// Raw Payment row: { payment_id, invoice_id, amount, method, status,
//                    stripe_session_id, paidat, invoice:{ account:{ student:{ user:{name} } } } }
// ─────────────────────────────────────────────────────────────────────────────

class PaymentModel extends Equatable {
  final int id;
  final int invoiceId;
  final double amount;
  final String method; // card / cash / transfer
  final String status; // pending / completed / failed / refunded
  final String? stripeSessionId;
  final String paidAt;
  final String? studentName;

  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.status,
    this.stripeSessionId,
    required this.paidAt,
    this.studentName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final invoice = json['invoice'] as Map<String, dynamic>?;
    final account = invoice == null ? null : invoice['account'] as Map<String, dynamic>?;
    final student = account == null ? null : account['student'] as Map<String, dynamic>?;
    final user    = student == null ? null : student['user'] as Map<String, dynamic>?;
    double n(dynamic v) =>
        v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

    return PaymentModel(
      id: json['payment_id'] as int,
      invoiceId: json['invoice_id'] as int,
      amount: n(json['amount']),
      method: (json['method'] as String?) ?? 'card',
      status: (json['status'] as String?) ?? 'pending',
      stripeSessionId: json['stripe_session_id'] as String?,
      paidAt: (json['paidat'] as String?) ?? '',
      studentName: user?['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, amount, paidAt];
}

class PaymentsHistoryModel extends Equatable {
  final double totalPaid;
  final int count;
  final List<PaymentModel> payments;

  const PaymentsHistoryModel({
    required this.totalPaid,
    required this.count,
    required this.payments,
  });

  factory PaymentsHistoryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['payments'] as List<dynamic>? ?? const [];
    final tp = json['total_paid'];
    return PaymentsHistoryModel(
      totalPaid: tp is num ? tp.toDouble() : 0,
      count: (json['count'] as int?) ?? raw.length,
      payments: raw
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [totalPaid, count, payments];
}

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutSessionModel — what POST /payments/checkout returns
// Shape: { checkout_url, session_id, amount }
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutSessionModel extends Equatable {
  final String checkoutUrl;
  final String sessionId;
  final double amount;

  const CheckoutSessionModel({
    required this.checkoutUrl,
    required this.sessionId,
    required this.amount,
  });

  factory CheckoutSessionModel.fromJson(Map<String, dynamic> json) {
    final amt = json['amount'];
    return CheckoutSessionModel(
      checkoutUrl: json['checkout_url'] as String,
      sessionId: json['session_id'] as String,
      amount: amt is num ? amt.toDouble() : double.tryParse('$amt') ?? 0,
    );
  }

  @override
  List<Object?> get props => [sessionId, checkoutUrl, amount];
}

/// Result of polling GET /payments/checkout/{sessionId}/status
class CheckoutStatusModel extends Equatable {
  final String status; // pending / completed / failed / refunded
  final double amount;
  final int invoiceId;

  const CheckoutStatusModel({
    required this.status,
    required this.amount,
    required this.invoiceId,
  });

  bool get isTerminal =>
      status == 'completed' || status == 'failed' || status == 'refunded';

  factory CheckoutStatusModel.fromJson(Map<String, dynamic> json) {
    final amt = json['amount'];
    return CheckoutStatusModel(
      status: (json['status'] as String?) ?? 'pending',
      amount: amt is num ? amt.toDouble() : double.tryParse('$amt') ?? 0,
      invoiceId: json['invoice_id'] as int,
    );
  }

  @override
  List<Object?> get props => [status, amount, invoiceId];
}

// ─────────────────────────────────────────────────────────────────────────────
// Bus events — timeline of stop events for a child's trips
// Item shape (from StopEvent model): { event_id, stop_id, stop_name,
//   event_type: 'arrive'|'depart'|'board'|'alight', occurred_at, ... }
// ─────────────────────────────────────────────────────────────────────────────

class BusEventModel extends Equatable {
  final int id;
  final String eventType; // arrive / depart / board / alight
  final String? stopName;
  final String occurredAt;

  const BusEventModel({
    required this.id,
    required this.eventType,
    this.stopName,
    required this.occurredAt,
  });

  factory BusEventModel.fromJson(Map<String, dynamic> json) => BusEventModel(
        id: (json['event_id'] ?? json['id']) as int,
        eventType: (json['event_type'] as String?) ?? 'arrive',
        stopName: (json['stop_name'] ?? json['stop']?['name']) as String?,
        occurredAt: (json['occurred_at'] ?? json['created_at'] ?? '') as String,
      );

  @override
  List<Object?> get props => [id, eventType, occurredAt];
}
