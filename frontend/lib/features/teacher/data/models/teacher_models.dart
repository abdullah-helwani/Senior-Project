import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class TeacherDashboardModel extends Equatable {
  final String name;
  final int todayClassesCount;
  final int pendingGradingCount;
  final int unreadNotificationsCount;
  final int totalStudents;

  const TeacherDashboardModel({
    required this.name,
    required this.todayClassesCount,
    required this.pendingGradingCount,
    required this.unreadNotificationsCount,
    required this.totalStudents,
  });

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) =>
      TeacherDashboardModel(
        name: json['name'] as String,
        todayClassesCount: (json['today_classes_count'] as int?) ?? 0,
        pendingGradingCount: (json['pending_grading_count'] as int?) ?? 0,
        unreadNotificationsCount:
            (json['unread_notifications_count'] as int?) ?? 0,
        totalStudents: (json['total_students'] as int?) ?? 0,
      );

  @override
  List<Object> get props => [
        name, todayClassesCount, pendingGradingCount,
        unreadNotificationsCount, totalStudents,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile
// ─────────────────────────────────────────────────────────────────────────────

class TeacherProfileModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? subject;
  final String? qualification;
  final String? schoolYear;
  final int? classCount;

  const TeacherProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.subject,
    this.qualification,
    this.schoolYear,
    this.classCount,
  });

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) =>
      TeacherProfileModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        subject: json['subject'] as String?,
        qualification: json['qualification'] as String?,
        schoolYear: json['school_year'] as String?,
        classCount: json['class_count'] as int?,
      );

  @override
  List<Object?> get props =>
      [id, name, email, phone, subject, qualification, schoolYear, classCount];
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule
// ─────────────────────────────────────────────────────────────────────────────

class TeacherScheduleSlotModel extends Equatable {
  final int id;
  final String day;
  final String startTime;
  final String endTime;
  final String className;
  final String subject;
  final int order;

  const TeacherScheduleSlotModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.subject,
    required this.order,
  });

  factory TeacherScheduleSlotModel.fromJson(Map<String, dynamic> json) =>
      TeacherScheduleSlotModel(
        id: (json['slot_id'] ?? json['id'] ?? 0) as int,
        day: (json['day'] ?? json['dayofweek'] ?? '') as String,
        startTime: (json['start_time'] ?? json['starttime'] ?? '') as String,
        endTime: (json['end_time'] ?? json['endtime'] ?? '') as String,
        className: (json['class_name'] ?? json['grade'] ?? json['section'] ?? '') as String,
        subject: (json['subject'] ?? '') as String,
        order: (json['order'] as int?) ?? 0,
      );

  @override
  List<Object> get props =>
      [id, day, startTime, endTime, className, subject, order];
}

// ─────────────────────────────────────────────────────────────────────────────
// Students in class
// ─────────────────────────────────────────────────────────────────────────────

class TeacherClassModel extends Equatable {
  final int id;
  final String name;
  final String subject;
  final List<ClassStudentModel> students;

  const TeacherClassModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.students,
  });

  factory TeacherClassModel.fromJson(Map<String, dynamic> json) {
    // Backend's `/teacher/{id}/profile` returns assignments as
    // `{ subject: <name>, section: <name>, class: <name>, school_year: <name> }`
    // — none of the fields are typed `int` and `students` is absent. Map
    // tolerantly so a stale row (subject deleted, etc.) doesn't crash parsing.
    final subjectField = json['subject'];
    final sectionField = json['section'];
    final classField = json['class'];
    return TeacherClassModel(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ??
          (sectionField is String ? sectionField : null) ??
          (classField is String ? classField : null) ??
          'Class',
      subject: (subjectField is String ? subjectField : null) ?? '',
      students: (json['students'] as List<dynamic>? ?? [])
          .map((s) =>
              ClassStudentModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object> get props => [id, name, subject, students];
}

class ClassStudentModel extends Equatable {
  final int id;
  final String name;
  final double? averageScore;
  final double? attendancePercent;

  const ClassStudentModel({
    required this.id,
    required this.name,
    this.averageScore,
    this.attendancePercent,
  });

  factory ClassStudentModel.fromJson(Map<String, dynamic> json) =>
      ClassStudentModel(
        id: json['id'] as int,
        name: json['name'] as String,
        averageScore: (json['average_score'] as num?)?.toDouble(),
        attendancePercent:
            (json['attendance_percent'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [id, name, averageScore, attendancePercent];
}

// ─────────────────────────────────────────────────────────────────────────────
// Homework
// ─────────────────────────────────────────────────────────────────────────────

class TeacherHomeworkModel extends Equatable {
  final int id;
  final String title;
  final String subject;
  final String className;
  final String dueDate;
  final String description;

  /// 'published' | 'draft'
  final String status;
  final int submissionCount;
  final int totalStudents;

  const TeacherHomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.dueDate,
    required this.description,
    required this.status,
    required this.submissionCount,
    required this.totalStudents,
  });

  int get pendingGrading => submissionCount; // simplified for mock

  factory TeacherHomeworkModel.fromJson(Map<String, dynamic> json) =>
      TeacherHomeworkModel(
        id: json['id'] as int,
        title: json['title'] as String,
        subject: json['subject'] as String,
        className: json['class_name'] as String,
        dueDate: json['due_date'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        submissionCount: (json['submission_count'] as int?) ?? 0,
        totalStudents: (json['total_students'] as int?) ?? 0,
      );

  @override
  List<Object> get props =>
      [id, title, subject, className, dueDate, status, submissionCount];
}

class HomeworkSubmissionModel extends Equatable {
  final int id;
  final int studentId;
  final String studentName;
  final String? submittedAt;
  final String? content;
  final double? grade;
  final String? feedback;

  /// 'pending' | 'submitted' | 'graded' | 'late'
  final String status;

  const HomeworkSubmissionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.submittedAt,
    this.content,
    this.grade,
    this.feedback,
    required this.status,
  });

  HomeworkSubmissionModel copyWith({double? grade, String? feedback, String? status}) =>
      HomeworkSubmissionModel(
        id: id,
        studentId: studentId,
        studentName: studentName,
        submittedAt: submittedAt,
        content: content,
        grade: grade ?? this.grade,
        feedback: feedback ?? this.feedback,
        status: status ?? this.status,
      );

  factory HomeworkSubmissionModel.fromJson(Map<String, dynamic> json) =>
      HomeworkSubmissionModel(
        // Backend PK is "submission_id"
        id: (json['submission_id'] ?? json['id']) as int,
        studentId: json['student_id'] as int,
        studentName: json['student_name'] as String,
        // Backend column is "submittedat" (camelCase-smashed)
        submittedAt: (json['submitted_at'] ?? json['submittedat']) as String?,
        content: json['content'] as String?,
        // Backend field is "score" not "grade"
        grade: (json['score'] ?? json['grade'] as num?)?.toDouble(),
        feedback: json['feedback'] as String?,
        status: json['status'] as String,
      );

  @override
  List<Object?> get props =>
      [id, studentId, studentName, submittedAt, grade, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance
// ─────────────────────────────────────────────────────────────────────────────

class TeacherAttendanceSessionModel extends Equatable {
  final int id;
  final String date;
  final String className;
  final String subject;

  /// 'pending' | 'submitted'
  final String status;
  final List<AttendanceEntryModel> entries;

  const TeacherAttendanceSessionModel({
    required this.id,
    required this.date,
    required this.className,
    required this.subject,
    required this.status,
    required this.entries,
  });

  TeacherAttendanceSessionModel copyWith({
    List<AttendanceEntryModel>? entries,
    String? status,
  }) =>
      TeacherAttendanceSessionModel(
        id: id,
        date: date,
        className: className,
        subject: subject,
        status: status ?? this.status,
        entries: entries ?? this.entries,
      );

  factory TeacherAttendanceSessionModel.fromJson(
          Map<String, dynamic> json) =>
      TeacherAttendanceSessionModel(
        id: json['id'] as int,
        date: json['date'] as String,
        className: json['class_name'] as String,
        subject: json['subject'] as String,
        status: json['status'] as String,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) =>
                AttendanceEntryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object> get props =>
      [id, date, className, subject, status, entries];
}

class AttendanceEntryModel extends Equatable {
  final int studentId;
  final String studentName;

  /// 'present' | 'absent' | 'late' | 'excused'
  final String status;

  const AttendanceEntryModel({
    required this.studentId,
    required this.studentName,
    required this.status,
  });

  AttendanceEntryModel copyWith({String? status}) => AttendanceEntryModel(
        studentId: studentId,
        studentName: studentName,
        status: status ?? this.status,
      );

  factory AttendanceEntryModel.fromJson(Map<String, dynamic> json) =>
      AttendanceEntryModel(
        studentId: json['student_id'] as int,
        studentName: json['student_name'] as String,
        status: json['status'] as String,
      );

  @override
  List<Object> get props => [studentId, studentName, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications (reuse same shape as student)
// ─────────────────────────────────────────────────────────────────────────────

class TeacherNotificationModel extends Equatable {
  final int id;
  final String title;
  final String? body;
  final bool isRead;
  final String createdAt;

  const TeacherNotificationModel({
    required this.id,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
  });

  TeacherNotificationModel copyWith({bool? isRead}) =>
      TeacherNotificationModel(
        id: id,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory TeacherNotificationModel.fromJson(Map<String, dynamic> json) =>
      TeacherNotificationModel(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: (json['is_read'] as bool?) ?? false,
        createdAt: json['created_at'] as String,
      );

  @override
  List<Object?> get props => [id, title, isRead, createdAt];
}
