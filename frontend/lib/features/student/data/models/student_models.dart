import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class StudentDashboardModel extends Equatable {
  final String name;
  final int todayClassesCount;
  final int unreadNotificationsCount;
  final double attendancePercent;
  final int upcomingHomeworkCount;

  const StudentDashboardModel({
    required this.name,
    required this.todayClassesCount,
    required this.unreadNotificationsCount,
    required this.attendancePercent,
    required this.upcomingHomeworkCount,
  });

  factory StudentDashboardModel.fromMe(Map<String, dynamic> json) =>
      StudentDashboardModel(
        name: json['name'] as String,
        todayClassesCount:
            (json['today_classes_count'] as int?) ?? 0,
        unreadNotificationsCount:
            (json['unread_notifications_count'] as int?) ?? 0,
        attendancePercent:
            ((json['attendance_percent'] as num?) ?? 0).toDouble(),
        upcomingHomeworkCount:
            (json['upcoming_homework_count'] as int?) ?? 0,
      );

  @override
  List<Object> get props => [
        name,
        todayClassesCount,
        unreadNotificationsCount,
        attendancePercent,
        upcomingHomeworkCount,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile
// ─────────────────────────────────────────────────────────────────────────────

class StudentProfileModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? dob;
  final String? gender;
  final String? address;
  final String? className;
  final String? section;
  final String? schoolYear;

  const StudentProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dob,
    this.gender,
    this.address,
    this.className,
    this.section,
    this.schoolYear,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) =>
      StudentProfileModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        dob: json['dob'] as String?,
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        className: json['class_name'] as String?,
        section: json['section'] as String?,
        schoolYear: json['school_year'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, email, phone, dob, gender, address, className, section, schoolYear];
}

// ─────────────────────────────────────────────────────────────────────────────
// Marks
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentModel extends Equatable {
  final int id;
  final String title;
  final String subject;

  /// 'quiz' | 'midterm' | 'final' | 'homework' | etc.
  final String type;
  final double score;
  final double maxScore;
  final String? grade;
  final String date;
  final String? publishedDate;
  final String? feedback;

  const AssessmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.score,
    required this.maxScore,
    this.grade,
    required this.date,
    this.publishedDate,
    this.feedback,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  factory AssessmentModel.fromJson(Map<String, dynamic> json) =>
      AssessmentModel(
        // PK: result_id > assessment_id > id (backend uses non-standard PKs)
        id: (json['result_id'] ?? json['assessment_id'] ?? json['id']) as int,
        title: json['title'] as String,
        subject: json['subject'] as String,
        // Backend column is "assessmenttype" (camelCase-smashed)
        type: (json['type'] ?? json['assessmenttype'] ?? '') as String,
        score: ((json['score'] as num?) ?? 0).toDouble(),
        // Backend column is "maxscore" (camelCase-smashed)
        maxScore: ((json['max_score'] ?? json['maxscore'] as num?) ?? 100).toDouble(),
        grade: json['grade'] as String?,
        date: json['date'] as String,
        // Backend column is "publishedat" (camelCase-smashed)
        publishedDate: (json['published_date'] ?? json['publishedat']) as String?,
        feedback: json['feedback'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, title, subject, type, score, maxScore, grade, date];
}

class MarksSummaryModel extends Equatable {
  final double overallAverage;
  final double highest;
  final double lowest;
  final Map<String, double> subjectAverages; // subject → avg %

  const MarksSummaryModel({
    required this.overallAverage,
    required this.highest,
    required this.lowest,
    required this.subjectAverages,
  });

  factory MarksSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['subject_averages'] as Map<String, dynamic>? ?? {};
    return MarksSummaryModel(
      overallAverage:
          ((json['overall_average'] as num?) ?? 0).toDouble(),
      highest: ((json['highest'] as num?) ?? 0).toDouble(),
      lowest: ((json['lowest'] as num?) ?? 0).toDouble(),
      subjectAverages:
          raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  @override
  List<Object> get props =>
      [overallAverage, highest, lowest, subjectAverages];
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleSlotModel extends Equatable {
  final int id;
  final String day; // 'monday' ... 'sunday'
  final String startTime;
  final String endTime;
  final String subject;
  final String teacherName;
  final int order;

  const ScheduleSlotModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    required this.order,
  });

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) =>
      ScheduleSlotModel(
        // Backend PK is "slot_id"
        id: (json['slot_id'] ?? json['id']) as int,
        // Backend column is "dayofweek" (camelCase-smashed)
        day: (json['day'] ?? json['dayofweek'] ?? '') as String,
        // Backend column is "starttime" (camelCase-smashed)
        startTime: (json['start_time'] ?? json['starttime'] ?? '') as String,
        endTime: (json['end_time'] ?? json['endtime'] ?? '') as String,
        subject: json['subject'] as String,
        teacherName: json['teacher_name'] as String,
        order: (json['order'] as int?) ?? 0,
      );

  @override
  List<Object> get props =>
      [id, day, startTime, endTime, subject, teacherName, order];
}

// ─────────────────────────────────────────────────────────────────────────────
// Homework
// ─────────────────────────────────────────────────────────────────────────────

class HomeworkModel extends Equatable {
  final int id;
  final String title;
  final String subject;
  final String dueDate;
  final String teacherName;

  /// 'pending' | 'submitted' | 'late' | 'graded'
  final String status;
  final String? description;
  final String? submittedContent;
  final String? submissionNotes;
  final double? grade;
  final String? gradeFeedback;

  const HomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.teacherName,
    required this.status,
    this.description,
    this.submittedContent,
    this.submissionNotes,
    this.grade,
    this.gradeFeedback,
  });

  bool get isSubmitted => status == 'submitted' || status == 'graded';

  factory HomeworkModel.fromJson(Map<String, dynamic> json) => HomeworkModel(
        id: json['id'] as int,
        title: json['title'] as String,
        subject: json['subject'] as String,
        dueDate: json['due_date'] as String,
        teacherName: json['teacher_name'] as String,
        status: json['status'] as String,
        description: json['description'] as String?,
        submittedContent: json['submitted_content'] as String?,
        submissionNotes: json['submission_notes'] as String?,
        grade: (json['grade'] as num?)?.toDouble(),
        gradeFeedback: json['grade_feedback'] as String?,
      );

  @override
  List<Object?> get props => [id, title, subject, dueDate, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceRecordModel extends Equatable {
  final String date;

  /// 'present' | 'absent' | 'late' | 'excused'
  final String status;
  final String? note;

  const AttendanceRecordModel({
    required this.date,
    required this.status,
    this.note,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        date: json['date'] as String,
        status: json['status'] as String,
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [date, status, note];
}

class AttendanceSummaryModel extends Equatable {
  final double percent;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final List<AttendanceRecordModel> records;

  const AttendanceSummaryModel({
    required this.percent,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.records,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['records'] as List<dynamic>? ?? [];
    return AttendanceSummaryModel(
      percent: ((json['percent'] as num?) ?? 0).toDouble(),
      present: (json['present'] as int?) ?? 0,
      absent: (json['absent'] as int?) ?? 0,
      late: (json['late'] as int?) ?? 0,
      excused: (json['excused'] as int?) ?? 0,
      records: raw
          .map((r) =>
              AttendanceRecordModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object> get props =>
      [percent, present, absent, late, excused, records];
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel extends Equatable {
  final int id;
  final int recipientId;
  final String title;
  final String? body;
  final bool isRead;
  final String createdAt;
  final bool isWarning;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
    this.isWarning = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json,
      {bool isWarning = false}) =>
      NotificationModel(
        id: json['id'] as int,
        recipientId: (json['recipient_id'] as int?) ?? json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: (json['is_read'] as bool?) ?? false,
        createdAt: json['created_at'] as String,
        isWarning: isWarning,
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        recipientId: recipientId,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        isWarning: isWarning,
      );

  @override
  List<Object?> get props => [id, recipientId, title, isRead, createdAt, isWarning];
}

// ─────────────────────────────────────────────────────────────────────────────
// Bus
// ─────────────────────────────────────────────────────────────────────────────

class BusAssignmentModel extends Equatable {
  final String busPlate;
  final String routeName;
  final String pickupStopName;
  final List<BusStopModel> stops;

  const BusAssignmentModel({
    required this.busPlate,
    required this.routeName,
    required this.pickupStopName,
    required this.stops,
  });

  factory BusAssignmentModel.fromJson(Map<String, dynamic> json) =>
      BusAssignmentModel(
        busPlate: json['bus_plate'] as String,
        routeName: json['route_name'] as String,
        pickupStopName: json['pickup_stop_name'] as String,
        stops: (json['stops'] as List<dynamic>? ?? [])
            .map((s) => BusStopModel.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object> get props => [busPlate, routeName, pickupStopName, stops];
}

class BusStopModel extends Equatable {
  final int id;
  final String name;
  final int order;

  const BusStopModel({required this.id, required this.name, required this.order});

  factory BusStopModel.fromJson(Map<String, dynamic> json) => BusStopModel(
        // Backend PK is "stop_id"
        id: (json['stop_id'] ?? json['id']) as int,
        name: json['name'] as String,
        // Backend column is "stoporder" (camelCase-smashed)
        order: (json['stoporder'] ?? json['order'] ?? 0) as int,
      );

  @override
  List<Object> get props => [id, name, order];
}

class BusLiveLocationModel extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? driverName;
  final String? routeName;
  final String? updatedAt;

  const BusLiveLocationModel({
    this.latitude,
    this.longitude,
    this.driverName,
    this.routeName,
    this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory BusLiveLocationModel.fromJson(Map<String, dynamic> json) {
    // Backend returns { trip: {...}, location: { latitude, longitude } }
    // Unwrap "location" if present, otherwise read top-level fields.
    final loc = (json['location'] as Map<String, dynamic>?) ?? json;
    final trip = (json['trip'] as Map<String, dynamic>?) ?? json;
    return BusLiveLocationModel(
      latitude: (loc['latitude'] as num?)?.toDouble(),
      longitude: (loc['longitude'] as num?)?.toDouble(),
      driverName: json['driver_name'] as String?,
      routeName: json['route_name'] as String?,
      // Backend column is "capturedat" (camelCase-smashed)
      updatedAt: (loc['capturedat'] ?? loc['updated_at'] ?? trip['updated_at']) as String?,
    );
  }

  @override
  List<Object?> get props =>
      [latitude, longitude, driverName, routeName, updatedAt];
}

class BusEventModel extends Equatable {
  final int id;
  final String date;
  final String stopName;

  /// 'boarded' | 'dropped'
  final String eventType;
  final String time;

  const BusEventModel({
    required this.id,
    required this.date,
    required this.stopName,
    required this.eventType,
    required this.time,
  });

  factory BusEventModel.fromJson(Map<String, dynamic> json) => BusEventModel(
        // Backend PK is "trpstopevent_id" (typo in backend — missing 'i')
        id: (json['trpstopevent_id'] ?? json['id']) as int,
        date: json['date'] as String,
        stopName: json['stop_name'] as String,
        // Backend column is "eventtype" (camelCase-smashed)
        eventType: (json['event_type'] ?? json['eventtype'] ?? '') as String,
        // Backend column is "eventat" (camelCase-smashed)
        time: (json['time'] ?? json['eventat'] ?? '') as String,
      );

  @override
  List<Object> get props => [id, date, stopName, eventType, time];
}
