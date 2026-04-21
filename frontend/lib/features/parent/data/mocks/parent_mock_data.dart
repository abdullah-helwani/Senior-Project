import 'package:first_try/features/parent/data/models/parent_models.dart';

class ParentMockData {
  // ── Parent profile ────────────────────────────────────────────────────────
  static const parentProfile = ParentProfileModel(
    id: 1,
    name: 'Khalid Omar',
    email: 'khalid@parent.com',
    phone: '+963 933 444 555',
    children: [
      ChildSummaryModel(
        id: 1, name: 'Omar Khalid',
        className: 'Grade 9', section: 'Section A',
        attendancePercent: 91.5, averageScore: 85.0, pendingHomeworkCount: 2,
      ),
      ChildSummaryModel(
        id: 2, name: 'Lina Khalid',
        className: 'Grade 7', section: 'Section B',
        attendancePercent: 97.0, averageScore: 92.0, pendingHomeworkCount: 1,
      ),
    ],
  );

  // ── Child profiles ────────────────────────────────────────────────────────
  static const child1Profile = ChildProfileModel(
    id: 1, name: 'Omar Khalid',
    dob: '2011-03-15', gender: 'Male',
    className: 'Grade 9', section: 'Section A', schoolYear: '2025 – 2026',
  );

  static const child2Profile = ChildProfileModel(
    id: 2, name: 'Lina Khalid',
    dob: '2013-07-22', gender: 'Female',
    className: 'Grade 7', section: 'Section B', schoolYear: '2025 – 2026',
  );

  // ── Marks (child 1) ───────────────────────────────────────────────────────
  static List<ParentAssessmentModel> get marksChild1 => [
        const ParentAssessmentModel(id: 1, title: 'Chapter 3 Quiz',      subject: 'Mathematics', type: 'quiz',     score: 18, maxScore: 20,  grade: 'A',  date: '2026-03-10'),
        const ParentAssessmentModel(id: 2, title: 'Midterm Exam',         subject: 'Mathematics', type: 'midterm',  score: 76, maxScore: 100, grade: 'B+', date: '2026-02-20'),
        const ParentAssessmentModel(id: 3, title: 'Essay — Climate',      subject: 'English',     type: 'homework', score: 45, maxScore: 50,  grade: 'A',  date: '2026-03-05'),
        const ParentAssessmentModel(id: 4, title: 'Midterm Exam',         subject: 'English',     type: 'midterm',  score: 68, maxScore: 100, grade: 'B',  date: '2026-02-22', feedback: 'Good structure but needs more detail.'),
        const ParentAssessmentModel(id: 5, title: 'Lab Report',           subject: 'Science',     type: 'homework', score: 28, maxScore: 30,  grade: 'A',  date: '2026-03-01'),
        const ParentAssessmentModel(id: 6, title: 'Midterm Exam',         subject: 'Science',     type: 'midterm',  score: 81, maxScore: 100, grade: 'A-', date: '2026-02-21'),
        const ParentAssessmentModel(id: 7, title: 'Chapter 2 Quiz',       subject: 'History',     type: 'quiz',     score: 14, maxScore: 20,  grade: 'B',  date: '2026-03-08'),
      ];

  // ── Marks (child 2) ───────────────────────────────────────────────────────
  static List<ParentAssessmentModel> get marksChild2 => [
        const ParentAssessmentModel(id: 8,  title: 'Unit Test',           subject: 'Mathematics', type: 'quiz',     score: 19, maxScore: 20,  grade: 'A+', date: '2026-03-12'),
        const ParentAssessmentModel(id: 9,  title: 'Midterm Exam',        subject: 'Mathematics', type: 'midterm',  score: 88, maxScore: 100, grade: 'A',  date: '2026-02-20'),
        const ParentAssessmentModel(id: 10, title: 'Reading Comprehension',subject: 'English',     type: 'homework', score: 47, maxScore: 50,  grade: 'A',  date: '2026-03-06'),
        const ParentAssessmentModel(id: 11, title: 'Midterm Exam',        subject: 'Science',     type: 'midterm',  score: 90, maxScore: 100, grade: 'A',  date: '2026-02-23'),
      ];

  // ── Attendance (child 1) ──────────────────────────────────────────────────
  static ParentAttendanceSummaryModel get attendanceChild1 {
    final records = <ParentAttendanceRecordModel>[];
    final now = DateTime.now();
    final statuses = ['present','present','present','present','present','present','present','late','present','absent'];
    for (int i = 30; i >= 1; i--) {
      final d = now.subtract(Duration(days: i));
      if (d.weekday <= 5) {
        records.add(ParentAttendanceRecordModel(
          date: d.toIso8601String().split('T').first,
          status: statuses[i % statuses.length],
        ));
      }
    }
    return ParentAttendanceSummaryModel(
      percent: 91.5,
      present: records.where((r) => r.status == 'present').length,
      absent: records.where((r) => r.status == 'absent').length,
      late: records.where((r) => r.status == 'late').length,
      excused: 0,
      records: records,
    );
  }

  // ── Attendance (child 2) ──────────────────────────────────────────────────
  static ParentAttendanceSummaryModel get attendanceChild2 {
    final records = <ParentAttendanceRecordModel>[];
    final now = DateTime.now();
    final statuses = ['present','present','present','present','present','present','present','present','present','late'];
    for (int i = 30; i >= 1; i--) {
      final d = now.subtract(Duration(days: i));
      if (d.weekday <= 5) {
        records.add(ParentAttendanceRecordModel(
          date: d.toIso8601String().split('T').first,
          status: statuses[i % statuses.length],
        ));
      }
    }
    return ParentAttendanceSummaryModel(
      percent: 97.0,
      present: records.where((r) => r.status == 'present').length,
      absent: records.where((r) => r.status == 'absent').length,
      late: records.where((r) => r.status == 'late').length,
      excused: 0,
      records: records,
    );
  }

  // ── Homework (child 1) ────────────────────────────────────────────────────
  static List<ParentHomeworkModel> get homeworkChild1 => [
        const ParentHomeworkModel(id: 1, title: 'Algebra Exercises — Ch. 4', subject: 'Mathematics', dueDate: '2026-04-15', teacherName: 'Mr. Ibrahim', status: 'pending',   description: 'Complete exercises 1–20 on page 87.'),
        const ParentHomeworkModel(id: 2, title: 'Short Story Analysis',       subject: 'English',     dueDate: '2026-04-16', teacherName: 'Ms. Layla',   status: 'pending',   description: 'Write 400 words on "The Gift of the Magi".'),
        const ParentHomeworkModel(id: 3, title: 'Photosynthesis Summary',     subject: 'Science',     dueDate: '2026-04-10', teacherName: 'Dr. Nour',    status: 'submitted', description: 'Summarise light-dependent reactions.'),
        const ParentHomeworkModel(id: 4, title: 'WWI Timeline',               subject: 'History',     dueDate: '2026-04-05', teacherName: 'Mr. Khaled',  status: 'graded',    description: 'Create a detailed timeline.', grade: 47, gradeFeedback: 'Good detail. Missing armistice date.'),
        const ParentHomeworkModel(id: 5, title: 'Fractions Worksheet',        subject: 'Mathematics', dueDate: '2026-04-02', teacherName: 'Mr. Ibrahim', status: 'late',      description: 'Complete all 30 questions.'),
      ];

  // ── Homework (child 2) ────────────────────────────────────────────────────
  static List<ParentHomeworkModel> get homeworkChild2 => [
        const ParentHomeworkModel(id: 6, title: 'Nature Essay',    subject: 'English',     dueDate: '2026-04-14', teacherName: 'Ms. Hana',    status: 'pending',   description: 'Write 300 words about nature.'),
        const ParentHomeworkModel(id: 7, title: 'Number Patterns', subject: 'Mathematics', dueDate: '2026-04-08', teacherName: 'Mr. Sami',    status: 'submitted', description: 'Complete the worksheet.'),
        const ParentHomeworkModel(id: 8, title: 'Plant Life Cycle',subject: 'Science',     dueDate: '2026-04-06', teacherName: 'Ms. Rima',    status: 'graded',    description: 'Draw and label plant life cycle.', grade: 48, gradeFeedback: 'Excellent diagrams!'),
      ];

  // ── Schedule (child 1) ────────────────────────────────────────────────────
  static List<ParentScheduleSlotModel> get scheduleChild1 => [
        const ParentScheduleSlotModel(id: 1,  day: 'monday',    startTime: '07:30', endTime: '08:15', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 1),
        const ParentScheduleSlotModel(id: 2,  day: 'monday',    startTime: '08:20', endTime: '09:05', subject: 'English',     teacherName: 'Ms. Layla',   order: 2),
        const ParentScheduleSlotModel(id: 3,  day: 'monday',    startTime: '09:10', endTime: '09:55', subject: 'Science',     teacherName: 'Dr. Nour',    order: 3),
        const ParentScheduleSlotModel(id: 4,  day: 'monday',    startTime: '10:10', endTime: '10:55', subject: 'History',     teacherName: 'Mr. Khaled',  order: 4),
        const ParentScheduleSlotModel(id: 5,  day: 'tuesday',   startTime: '07:30', endTime: '08:15', subject: 'English',     teacherName: 'Ms. Layla',   order: 1),
        const ParentScheduleSlotModel(id: 6,  day: 'tuesday',   startTime: '08:20', endTime: '09:05', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 2),
        const ParentScheduleSlotModel(id: 7,  day: 'wednesday', startTime: '07:30', endTime: '08:15', subject: 'History',     teacherName: 'Mr. Khaled',  order: 1),
        const ParentScheduleSlotModel(id: 8,  day: 'wednesday', startTime: '08:20', endTime: '09:05', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 2),
        const ParentScheduleSlotModel(id: 9,  day: 'thursday',  startTime: '07:30', endTime: '08:15', subject: 'Science',     teacherName: 'Dr. Nour',    order: 1),
        const ParentScheduleSlotModel(id: 10, day: 'thursday',  startTime: '08:20', endTime: '09:05', subject: 'History',     teacherName: 'Mr. Khaled',  order: 2),
      ];

  // ── Schedule (child 2) ────────────────────────────────────────────────────
  static List<ParentScheduleSlotModel> get scheduleChild2 => [
        const ParentScheduleSlotModel(id: 11, day: 'monday',    startTime: '07:30', endTime: '08:15', subject: 'Arabic',      teacherName: 'Ms. Nadia',   order: 1),
        const ParentScheduleSlotModel(id: 12, day: 'monday',    startTime: '08:20', endTime: '09:05', subject: 'Mathematics', teacherName: 'Mr. Sami',    order: 2),
        const ParentScheduleSlotModel(id: 13, day: 'tuesday',   startTime: '07:30', endTime: '08:15', subject: 'Science',     teacherName: 'Ms. Rima',    order: 1),
        const ParentScheduleSlotModel(id: 14, day: 'wednesday', startTime: '07:30', endTime: '08:15', subject: 'English',     teacherName: 'Ms. Hana',    order: 1),
        const ParentScheduleSlotModel(id: 15, day: 'thursday',  startTime: '07:30', endTime: '08:15', subject: 'Mathematics', teacherName: 'Mr. Sami',    order: 1),
      ];

  // ── Bus ───────────────────────────────────────────────────────────────────
  static const busChild1 = ParentBusModel(
    busPlate: 'SB-1234',
    routeName: 'Route A — North District',
    pickupStopName: 'Main Gate',
    latitude: 33.513,
    longitude: 36.312,
    driverName: 'Ahmed Hassan',
    updatedAt: '2026-04-13T07:42:00Z',
  );

  static const busChild2 = ParentBusModel(
    busPlate: 'SB-5678',
    routeName: 'Route B — South District',
    pickupStopName: 'Park Avenue',
    latitude: 33.508,
    longitude: 36.298,
    driverName: 'Walid Nasser',
    updatedAt: '2026-04-13T07:38:00Z',
  );

  // ── Notifications ─────────────────────────────────────────────────────────
  static List<ParentNotificationModel> get notifications => [
        const ParentNotificationModel(id: 1, title: 'Exam schedule published',    body: 'Final exams start May 5th. Check the portal for details.',                  isRead: false, createdAt: '2026-04-12T09:00:00Z'),
        const ParentNotificationModel(id: 2, title: 'School holiday — April 18',  body: 'School will be closed on April 18 for a national holiday.',                 isRead: false, createdAt: '2026-04-11T14:00:00Z'),
        const ParentNotificationModel(id: 3, title: 'Parent meeting — April 20',  body: 'Parent-teacher meetings will take place on April 20 from 4–7 PM.',          isRead: true,  createdAt: '2026-04-10T08:30:00Z'),
        const ParentNotificationModel(id: 4, title: 'Library books due',          body: 'Please return all library books by April 15.',                              isRead: true,  createdAt: '2026-04-09T10:00:00Z'),
      ];

  static List<ParentNotificationModel> get warnings => [
        ParentNotificationModel(id: 10, title: 'Late arrival — Omar (April 9)',    body: 'Omar arrived 20 minutes late on April 9.',                                  isRead: false, createdAt: '2026-04-09T07:50:00Z', isWarning: true),
        ParentNotificationModel(id: 11, title: 'Missing homework — Omar',          body: 'Omar did not submit the Fractions Worksheet due April 2.',                  isRead: true,  createdAt: '2026-04-03T09:00:00Z', isWarning: true),
      ];
}
