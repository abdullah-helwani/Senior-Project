import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TeacherMessage — sent list item / inbox item / detail
// Backend paginates; list endpoints return { data: [ ... ] } (sent) or
// { unread_count, messages: { data: [ ... ] } } (inbox).
// Item fields: id, sender_id, receiver_id, student_id, subject, body,
//              read_at, created_at, sender, receiver, student:{ user:{name} }
// ─────────────────────────────────────────────────────────────────────────────

class TeacherMessageModel extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String? senderName;
  final String? receiverName;
  final int? studentId;
  final String? studentName;
  final String? subject;
  final String body;
  final String? readAt;
  final String createdAt;

  const TeacherMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.senderName,
    this.receiverName,
    this.studentId,
    this.studentName,
    this.subject,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  /// Was the currently-authenticated teacher the sender?
  bool sentByMe(int myUserId) => senderId == myUserId;

  factory TeacherMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final receiver = json['receiver'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final studentUser =
        student == null ? null : student['user'] as Map<String, dynamic>?;

    return TeacherMessageModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      senderName: sender?['name'] as String?,
      receiverName: receiver?['name'] as String?,
      studentId: json['student_id'] as int?,
      studentName: studentUser?['name'] as String?,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, subject, readAt, createdAt];
}

/// Inbox wrapper — the inbox endpoint returns a separate unread count alongside
/// the paginated message list.
class TeacherInboxModel extends Equatable {
  final int unreadCount;
  final List<TeacherMessageModel> messages;

  const TeacherInboxModel({
    required this.unreadCount,
    required this.messages,
  });

  factory TeacherInboxModel.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    final list = raw is Map<String, dynamic>
        ? (raw['data'] as List<dynamic>? ?? const [])
        : (raw is List<dynamic> ? raw : const []);
    return TeacherInboxModel(
      unreadCount: (json['unread_count'] as int?) ?? 0,
      messages: list
          .map((m) => TeacherMessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [unreadCount, messages];
}

// ─────────────────────────────────────────────────────────────────────────────
// BehaviorLogModel — teacher-created behavior entries
// Item: { log_id, student_id, section_id, type, title, description,
//         date, notify_parent, student:{...}, section:{...} }
// ─────────────────────────────────────────────────────────────────────────────

class BehaviorLogModel extends Equatable {
  final int id;
  final int studentId;
  final int sectionId;
  final String? studentName;
  final String? sectionName;
  final String type; // positive / negative / neutral
  final String title;
  final String? description;
  final String date;
  final bool notifyParent;

  const BehaviorLogModel({
    required this.id,
    required this.studentId,
    required this.sectionId,
    this.studentName,
    this.sectionName,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.notifyParent = false,
  });

  factory BehaviorLogModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final studentUser =
        student == null ? null : student['user'] as Map<String, dynamic>?;
    final section = json['section'] as Map<String, dynamic>?;

    return BehaviorLogModel(
      id: (json['log_id'] ?? json['id']) as int,
      studentId: json['student_id'] as int,
      sectionId: json['section_id'] as int,
      studentName: (studentUser?['name'] ?? student?['name']) as String?,
      sectionName: section?['name'] as String?,
      type: (json['type'] as String?) ?? 'neutral',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      date: (json['date'] as String?) ?? '',
      notifyParent: (json['notify_parent'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [id, type, title, date];
}

// ─────────────────────────────────────────────────────────────────────────────
// PerformanceReportModel — weekly report for a section
// Shape: {
//   section_id, week_start, week_end, total_sessions,
//   students: [ {
//     student_id, name,
//     attendance: { days_present, total_days, percentage, statuses:[...] },
//     assessments: { results:[{title, subject, score, max_score, percentage, grade}],
//                    average_score },
//     behavior:    { positive, negative, neutral, entries:[{type, title, date}] },
//   } ]
// }
// ─────────────────────────────────────────────────────────────────────────────

class StudentPerformanceModel extends Equatable {
  final int studentId;
  final String name;

  final int attendancePresentDays;
  final int attendanceTotalDays;
  final double? attendancePercentage;

  final List<PerformanceAssessmentModel> assessments;
  final double? averageScore;

  final int positiveBehaviors;
  final int negativeBehaviors;
  final int neutralBehaviors;

  const StudentPerformanceModel({
    required this.studentId,
    required this.name,
    required this.attendancePresentDays,
    required this.attendanceTotalDays,
    this.attendancePercentage,
    required this.assessments,
    this.averageScore,
    required this.positiveBehaviors,
    required this.negativeBehaviors,
    required this.neutralBehaviors,
  });

  factory StudentPerformanceModel.fromJson(Map<String, dynamic> json) {
    final att = (json['attendance'] as Map<String, dynamic>?) ?? const {};
    final asmts = (json['assessments'] as Map<String, dynamic>?) ?? const {};
    final beh = (json['behavior'] as Map<String, dynamic>?) ?? const {};
    final results = (asmts['results'] as List<dynamic>? ?? const [])
        .map((r) =>
            PerformanceAssessmentModel.fromJson(r as Map<String, dynamic>))
        .toList();

    double? nd(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

    return StudentPerformanceModel(
      studentId: json['student_id'] as int,
      name: (json['name'] as String?) ?? '',
      attendancePresentDays: (att['days_present'] as int?) ?? 0,
      attendanceTotalDays: (att['total_days'] as int?) ?? 0,
      attendancePercentage: nd(att['percentage']),
      assessments: results,
      averageScore: nd(asmts['average_score']),
      positiveBehaviors: (beh['positive'] as int?) ?? 0,
      negativeBehaviors: (beh['negative'] as int?) ?? 0,
      neutralBehaviors: (beh['neutral'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [studentId, name, averageScore, attendancePercentage];
}

class PerformanceAssessmentModel extends Equatable {
  final String title;
  final String subject;
  final double score;
  final double maxScore;
  final double? percentage;
  final String? grade;

  const PerformanceAssessmentModel({
    required this.title,
    required this.subject,
    required this.score,
    required this.maxScore,
    this.percentage,
    this.grade,
  });

  factory PerformanceAssessmentModel.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) =>
        v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    return PerformanceAssessmentModel(
      title: (json['title'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? '',
      score: n(json['score']),
      maxScore: n(json['max_score']),
      percentage:
          json['percentage'] == null ? null : n(json['percentage']),
      grade: json['grade'] as String?,
    );
  }

  @override
  List<Object?> get props => [title, subject, score, maxScore];
}

class PerformanceReportModel extends Equatable {
  final int sectionId;
  final String weekStart;
  final String weekEnd;
  final int totalSessions;
  final List<StudentPerformanceModel> students;

  const PerformanceReportModel({
    required this.sectionId,
    required this.weekStart,
    required this.weekEnd,
    required this.totalSessions,
    required this.students,
  });

  factory PerformanceReportModel.fromJson(Map<String, dynamic> json) {
    final raw = json['students'] as List<dynamic>? ?? const [];
    return PerformanceReportModel(
      sectionId: json['section_id'] as int,
      weekStart: (json['week_start'] as String?) ?? '',
      weekEnd: (json['week_end'] as String?) ?? '',
      totalSessions: (json['total_sessions'] as int?) ?? 0,
      students: raw
          .map((s) =>
              StudentPerformanceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [sectionId, weekStart, weekEnd, students];
}

// ─────────────────────────────────────────────────────────────────────────────
// SalaryPaymentModel
// Backend list shape: { teacher_id, total_paid, count, payments: [...] }
// ─────────────────────────────────────────────────────────────────────────────

class SalaryPaymentModel extends Equatable {
  final int id;
  final double amount;
  final String periodMonth; // YYYY-MM-01 typically
  final String? paidAt;
  final String? method;
  final String? status;

  const SalaryPaymentModel({
    required this.id,
    required this.amount,
    required this.periodMonth,
    this.paidAt,
    this.method,
    this.status,
  });

  factory SalaryPaymentModel.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) =>
        v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    return SalaryPaymentModel(
      id: (json['salarypayment_id'] ?? json['id']) as int,
      amount: n(json['amount']),
      periodMonth: (json['periodmonth'] as String?) ?? '',
      paidAt: (json['paidat'] ?? json['paid_at']) as String?,
      method: json['method'] as String?,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, periodMonth, amount, status];
}

class SalarySummaryModel extends Equatable {
  final double totalPaid;
  final int count;
  final List<SalaryPaymentModel> payments;

  const SalarySummaryModel({
    required this.totalPaid,
    required this.count,
    required this.payments,
  });

  factory SalarySummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['payments'] as List<dynamic>? ?? const [];
    final tp = json['total_paid'];
    return SalarySummaryModel(
      totalPaid: tp is num ? tp.toDouble() : 0,
      count: (json['count'] as int?) ?? raw.length,
      payments: raw
          .map((p) => SalaryPaymentModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [totalPaid, count, payments];
}

// ─────────────────────────────────────────────────────────────────────────────
// VacationRequestModel
// Item: { vacation_id, teacher_id, start_date, end_date, status, created_at }
// Status: pending / approved / rejected
// ─────────────────────────────────────────────────────────────────────────────

class VacationRequestModel extends Equatable {
  final int id;
  final String startDate;
  final String endDate;
  final String status;
  final String? createdAt;

  const VacationRequestModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get canCancel => isPending;

  factory VacationRequestModel.fromJson(Map<String, dynamic> json) =>
      VacationRequestModel(
        id: (json['vacation_id'] ?? json['id']) as int,
        startDate: (json['start_date'] as String?) ?? '',
        endDate: (json['end_date'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pending',
        createdAt: json['created_at'] as String?,
      );

  @override
  List<Object?> get props => [id, startDate, endDate, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// TeacherAvailabilityModel
// Item: { availability_id, teacher_id, dayofweek, start_time, end_time,
//         availabilitytype }
// ─────────────────────────────────────────────────────────────────────────────

class TeacherAvailabilityModel extends Equatable {
  final int id;
  final String dayOfWeek; // Monday..Sunday
  final String startTime; // HH:mm
  final String endTime;
  final String type; // available / unavailable / preferred

  const TeacherAvailabilityModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  factory TeacherAvailabilityModel.fromJson(Map<String, dynamic> json) =>
      TeacherAvailabilityModel(
        id: (json['availability_id'] ?? json['id']) as int,
        dayOfWeek: (json['dayofweek'] as String?) ?? '',
        startTime: (json['start_time'] as String?) ?? '',
        endTime: (json['end_time'] as String?) ?? '',
        type: (json['availabilitytype'] as String?) ?? 'available',
      );

  @override
  List<Object?> get props => [id, dayOfWeek, startTime, endTime, type];
}

// ─────────────────────────────────────────────────────────────────────────────
// Submissions response wrapper — the endpoint returns homework + summary +
// submissions. We keep the summary numbers for the UI header.
// ─────────────────────────────────────────────────────────────────────────────

class SubmissionsSummaryModel extends Equatable {
  final int totalEnrolled;
  final int totalSubmitted;
  final int totalGraded;
  final int notSubmitted;
  final double? averageScore;

  const SubmissionsSummaryModel({
    required this.totalEnrolled,
    required this.totalSubmitted,
    required this.totalGraded,
    required this.notSubmitted,
    this.averageScore,
  });

  factory SubmissionsSummaryModel.fromJson(Map<String, dynamic> json) {
    double? nd(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    return SubmissionsSummaryModel(
      totalEnrolled: (json['total_enrolled'] as int?) ?? 0,
      totalSubmitted: (json['total_submitted'] as int?) ?? 0,
      totalGraded: (json['total_graded'] as int?) ?? 0,
      notSubmitted: (json['not_submitted'] as int?) ?? 0,
      averageScore: nd(json['average_score']),
    );
  }

  @override
  List<Object?> get props =>
      [totalEnrolled, totalSubmitted, totalGraded, notSubmitted];
}
