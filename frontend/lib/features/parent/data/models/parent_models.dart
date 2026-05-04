import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Child summary (dashboard card per child)
// ─────────────────────────────────────────────────────────────────────────────

class ChildSummaryModel extends Equatable {
  final int id;
  final String name;
  final String className;
  final String section;
  final double attendancePercent;
  final double averageScore;
  final int pendingHomeworkCount;

  const ChildSummaryModel({
    required this.id,
    required this.name,
    required this.className,
    required this.section,
    required this.attendancePercent,
    required this.averageScore,
    required this.pendingHomeworkCount,
  });

  factory ChildSummaryModel.fromJson(Map<String, dynamic> json) =>
      ChildSummaryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        className: json['class_name'] as String,
        section: json['section'] as String,
        attendancePercent: ((json['attendance_percent'] as num?) ?? 0).toDouble(),
        averageScore: ((json['average_score'] as num?) ?? 0).toDouble(),
        pendingHomeworkCount: (json['pending_homework_count'] as int?) ?? 0,
      );

  @override
  List<Object> get props => [id, name, className, section, attendancePercent, averageScore, pendingHomeworkCount];
}

// ─────────────────────────────────────────────────────────────────────────────
// Child profile
// ─────────────────────────────────────────────────────────────────────────────

class ChildProfileModel extends Equatable {
  final int id;
  final String name;
  final String? dob;
  final String? gender;
  final String className;
  final String section;
  final String schoolYear;

  const ChildProfileModel({
    required this.id,
    required this.name,
    this.dob,
    this.gender,
    required this.className,
    required this.section,
    required this.schoolYear,
  });

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) =>
      ChildProfileModel(
        id: json['id'] as int,
        name: json['name'] as String,
        dob: json['dob'] as String?,
        gender: json['gender'] as String?,
        className: json['class_name'] as String,
        section: json['section'] as String,
        schoolYear: json['school_year'] as String,
      );

  @override
  List<Object?> get props => [id, name, dob, gender, className, section, schoolYear];
}

// ─────────────────────────────────────────────────────────────────────────────
// Parent profile
// ─────────────────────────────────────────────────────────────────────────────

class ParentProfileModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<ChildSummaryModel> children;

  const ParentProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.children,
  });

  factory ParentProfileModel.fromJson(Map<String, dynamic> json) =>
      ParentProfileModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        children: (json['children'] as List<dynamic>? ?? [])
            .map((c) => ChildSummaryModel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, name, email, phone, children];
}

// ─────────────────────────────────────────────────────────────────────────────
// Marks (reuse shape from student)
// ─────────────────────────────────────────────────────────────────────────────

class ParentAssessmentModel extends Equatable {
  final int id;
  final String title;
  final String subject;
  final String type;
  final double score;
  final double maxScore;
  final String? grade;
  final String date;
  final String? feedback;

  const ParentAssessmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.score,
    required this.maxScore,
    this.grade,
    required this.date,
    this.feedback,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  factory ParentAssessmentModel.fromJson(Map<String, dynamic> json) =>
      ParentAssessmentModel(
        id: (json['result_id'] ?? json['assessment_id'] ?? json['id']) as int,
        title: json['title'] as String,
        subject: json['subject'] as String,
        type: (json['type'] ?? json['assessmenttype'] ?? '') as String,
        score: ((json['score'] as num?) ?? 0).toDouble(),
        maxScore: ((json['max_score'] ?? json['maxscore'] as num?) ?? 100).toDouble(),
        grade: json['grade'] as String?,
        date: json['date'] as String,
        feedback: json['feedback'] as String?,
      );

  @override
  List<Object?> get props => [id, title, subject, type, score, maxScore, date];
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance
// ─────────────────────────────────────────────────────────────────────────────

class ParentAttendanceRecordModel extends Equatable {
  final String date;
  final String status;
  final String? note;

  const ParentAttendanceRecordModel({
    required this.date,
    required this.status,
    this.note,
  });

  factory ParentAttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      ParentAttendanceRecordModel(
        date: json['date'] as String,
        status: json['status'] as String,
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [date, status, note];
}

class ParentAttendanceSummaryModel extends Equatable {
  final double percent;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final List<ParentAttendanceRecordModel> records;

  const ParentAttendanceSummaryModel({
    required this.percent,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.records,
  });

  factory ParentAttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['records'] as List<dynamic>? ?? [];
    return ParentAttendanceSummaryModel(
      percent: ((json['percent'] as num?) ?? 0).toDouble(),
      present: (json['present'] as int?) ?? 0,
      absent: (json['absent'] as int?) ?? 0,
      late: (json['late'] as int?) ?? 0,
      excused: (json['excused'] as int?) ?? 0,
      records: raw
          .map((r) => ParentAttendanceRecordModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object> get props => [percent, present, absent, late, excused, records];
}

// ─────────────────────────────────────────────────────────────────────────────
// Homework
// ─────────────────────────────────────────────────────────────────────────────

class ParentHomeworkModel extends Equatable {
  final int id;
  final String title;
  final String subject;
  final String dueDate;
  final String teacherName;
  final String status;
  final String? description;
  final double? grade;
  final String? gradeFeedback;

  const ParentHomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.teacherName,
    required this.status,
    this.description,
    this.grade,
    this.gradeFeedback,
  });

  factory ParentHomeworkModel.fromJson(Map<String, dynamic> json) =>
      ParentHomeworkModel(
        id: json['id'] as int,
        title: json['title'] as String,
        subject: json['subject'] as String,
        dueDate: json['due_date'] as String,
        teacherName: json['teacher_name'] as String,
        status: json['status'] as String,
        description: json['description'] as String?,
        grade: (json['grade'] as num?)?.toDouble(),
        gradeFeedback: json['grade_feedback'] as String?,
      );

  @override
  List<Object?> get props => [id, title, subject, dueDate, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule
// ─────────────────────────────────────────────────────────────────────────────

class ParentScheduleSlotModel extends Equatable {
  final int id;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacherName;
  final int order;

  const ParentScheduleSlotModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    required this.order,
  });

  factory ParentScheduleSlotModel.fromJson(Map<String, dynamic> json) =>
      ParentScheduleSlotModel(
        id: (json['slot_id'] ?? json['id']) as int,
        day: (json['day'] ?? json['dayofweek'] ?? '') as String,
        startTime: (json['start_time'] ?? json['starttime'] ?? '') as String,
        endTime: (json['end_time'] ?? json['endtime'] ?? '') as String,
        subject: json['subject'] as String,
        teacherName: json['teacher_name'] as String,
        order: (json['order'] as int?) ?? 0,
      );

  @override
  List<Object> get props => [id, day, startTime, endTime, subject, teacherName, order];
}

// ─────────────────────────────────────────────────────────────────────────────
// Bus
// ─────────────────────────────────────────────────────────────────────────────

class ParentBusModel extends Equatable {
  final String busPlate;
  final String routeName;
  final String pickupStopName;
  final double? latitude;
  final double? longitude;
  final String? driverName;
  final String? updatedAt;

  const ParentBusModel({
    required this.busPlate,
    required this.routeName,
    required this.pickupStopName,
    this.latitude,
    this.longitude,
    this.driverName,
    this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory ParentBusModel.fromJson(Map<String, dynamic> json) {
    // The liveLocation endpoint returns { trip: {...}, location: {...} }.
    // The assignment endpoint returns the raw StudentBusAssignment with
    // nested bus/route/stop.  We normalise both shapes here.
    final trip = json['trip'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final bus = json['bus'] as Map<String, dynamic>?;
    final route = json['route'] as Map<String, dynamic>?;
    final stop = json['stop'] as Map<String, dynamic>?;
    final driver = trip?['driver'] as Map<String, dynamic>?;
    final driverUser = driver?['user'] as Map<String, dynamic>?;

    // lat/lng: prefer the dedicated location ping, fall back to top-level.
    final lat = (location?['latitude'] ?? json['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] ?? json['longitude'] as num?)?.toDouble();

    return ParentBusModel(
      busPlate: (json['bus_plate']
              ?? bus?['plate_number']
              ?? trip?['bus']?['plate_number']
              ?? '') as String,
      routeName: (json['route_name']
              ?? route?['name']
              ?? trip?['route']?['name']
              ?? '') as String,
      pickupStopName: (json['pickup_stop_name']
              ?? stop?['name']
              ?? '') as String,
      latitude: lat,
      longitude: lng,
      driverName: (json['driver_name']
              ?? driverUser?['name']
              ?? driver?['name']) as String?,
      updatedAt: (location?['capturedat']
              ?? json['updated_at']) as String?,
    );
  }

  @override
  List<Object?> get props => [busPlate, routeName, pickupStopName, latitude, longitude];
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

class ParentNotificationModel extends Equatable {
  final int id;
  final String title;
  final String? body;
  final bool isRead;
  final String createdAt;
  final bool isWarning;

  const ParentNotificationModel({
    required this.id,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
    this.isWarning = false,
  });

  ParentNotificationModel copyWith({bool? isRead}) => ParentNotificationModel(
        id: id,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        isWarning: isWarning,
      );

  factory ParentNotificationModel.fromJson(Map<String, dynamic> json,
          {bool isWarning = false}) =>
      ParentNotificationModel(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: (json['is_read'] as bool?) ?? false,
        createdAt: json['created_at'] as String,
        isWarning: isWarning,
      );

  @override
  List<Object?> get props => [id, title, isRead, createdAt, isWarning];
}
