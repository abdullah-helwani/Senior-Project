import 'package:first_try/features/student/data/models/student_models.dart';

class StudentMockData {
  // ── Dashboard ────────────────────────────────────────────────────────────
  static const dashboard = StudentDashboardModel(
    name: 'Omar Khalid',
    todayClassesCount: 5,
    unreadNotificationsCount: 3,
    attendancePercent: 91.5,
    upcomingHomeworkCount: 2,
  );

  // ── Profile ──────────────────────────────────────────────────────────────
  static const profile = StudentProfileModel(
    id: 1,
    name: 'Omar Khalid',
    email: 'omar@school.com',
    phone: '+963 944 111 222',
    dob: '2008-03-15',
    gender: 'Male',
    address: '12 Palm Street, Damascus',
    className: 'Grade 9',
    section: 'Section A',
    schoolYear: '2025 – 2026',
  );

  // ── Marks ────────────────────────────────────────────────────────────────
  static List<AssessmentModel> get marks => [
        const AssessmentModel(
            id: 1,
            title: 'Chapter 3 Quiz',
            subject: 'Mathematics',
            type: 'quiz',
            score: 18,
            maxScore: 20,
            grade: 'A',
            date: '2026-03-10'),
        const AssessmentModel(
            id: 2,
            title: 'Midterm Exam',
            subject: 'Mathematics',
            type: 'midterm',
            score: 76,
            maxScore: 100,
            grade: 'B+',
            date: '2026-02-20'),
        const AssessmentModel(
            id: 3,
            title: 'Essay — Climate Change',
            subject: 'English',
            type: 'homework',
            score: 45,
            maxScore: 50,
            grade: 'A',
            date: '2026-03-05'),
        const AssessmentModel(
            id: 4,
            title: 'Midterm Exam',
            subject: 'English',
            type: 'midterm',
            score: 68,
            maxScore: 100,
            grade: 'B',
            date: '2026-02-22',
            feedback: 'Good structure but needs more detail.'),
        const AssessmentModel(
            id: 5,
            title: 'Lab Report',
            subject: 'Science',
            type: 'homework',
            score: 28,
            maxScore: 30,
            grade: 'A',
            date: '2026-03-01'),
        const AssessmentModel(
            id: 6,
            title: 'Midterm Exam',
            subject: 'Science',
            type: 'midterm',
            score: 81,
            maxScore: 100,
            grade: 'A-',
            date: '2026-02-21'),
        const AssessmentModel(
            id: 7,
            title: 'Chapter 2 Quiz',
            subject: 'History',
            type: 'quiz',
            score: 14,
            maxScore: 20,
            grade: 'B',
            date: '2026-03-08'),
      ];

  static const marksSummary = MarksSummaryModel(
    overallAverage: 82.4,
    highest: 93.0,
    lowest: 68.0,
    subjectAverages: {
      'Mathematics': 85.0,
      'English': 78.5,
      'Science': 90.2,
      'History': 70.0,
    },
  );

  // ── Schedule ─────────────────────────────────────────────────────────────
  static List<ScheduleSlotModel> get schedule => [
        // Monday
        const ScheduleSlotModel(id: 1, day: 'monday', startTime: '07:30', endTime: '08:15', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 1),
        const ScheduleSlotModel(id: 2, day: 'monday', startTime: '08:20', endTime: '09:05', subject: 'English', teacherName: 'Ms. Layla', order: 2),
        const ScheduleSlotModel(id: 3, day: 'monday', startTime: '09:10', endTime: '09:55', subject: 'Science', teacherName: 'Dr. Nour', order: 3),
        const ScheduleSlotModel(id: 4, day: 'monday', startTime: '10:10', endTime: '10:55', subject: 'History', teacherName: 'Mr. Khaled', order: 4),
        const ScheduleSlotModel(id: 5, day: 'monday', startTime: '11:00', endTime: '11:45', subject: 'PE', teacherName: 'Coach Rami', order: 5),
        // Tuesday
        const ScheduleSlotModel(id: 6, day: 'tuesday', startTime: '07:30', endTime: '08:15', subject: 'English', teacherName: 'Ms. Layla', order: 1),
        const ScheduleSlotModel(id: 7, day: 'tuesday', startTime: '08:20', endTime: '09:05', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 2),
        const ScheduleSlotModel(id: 8, day: 'tuesday', startTime: '09:10', endTime: '09:55', subject: 'Art', teacherName: 'Ms. Hana', order: 3),
        const ScheduleSlotModel(id: 9, day: 'tuesday', startTime: '10:10', endTime: '10:55', subject: 'Science', teacherName: 'Dr. Nour', order: 4),
        // Wednesday
        const ScheduleSlotModel(id: 10, day: 'wednesday', startTime: '07:30', endTime: '08:15', subject: 'History', teacherName: 'Mr. Khaled', order: 1),
        const ScheduleSlotModel(id: 11, day: 'wednesday', startTime: '08:20', endTime: '09:05', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 2),
        const ScheduleSlotModel(id: 12, day: 'wednesday', startTime: '09:10', endTime: '09:55', subject: 'English', teacherName: 'Ms. Layla', order: 3),
        // Thursday
        const ScheduleSlotModel(id: 13, day: 'thursday', startTime: '07:30', endTime: '08:15', subject: 'Science', teacherName: 'Dr. Nour', order: 1),
        const ScheduleSlotModel(id: 14, day: 'thursday', startTime: '08:20', endTime: '09:05', subject: 'History', teacherName: 'Mr. Khaled', order: 2),
        const ScheduleSlotModel(id: 15, day: 'thursday', startTime: '09:10', endTime: '09:55', subject: 'Mathematics', teacherName: 'Mr. Ibrahim', order: 3),
        const ScheduleSlotModel(id: 16, day: 'thursday', startTime: '10:10', endTime: '10:55', subject: 'PE', teacherName: 'Coach Rami', order: 4),
      ];

  // ── Homework ──────────────────────────────────────────────────────────────
  static List<HomeworkModel> get homework => [
        const HomeworkModel(
            id: 1,
            title: 'Algebra Exercises — Ch. 4',
            subject: 'Mathematics',
            dueDate: '2026-04-15',
            teacherName: 'Mr. Ibrahim',
            status: 'pending',
            description: 'Complete exercises 1–20 on page 87. Show all your working.'),
        const HomeworkModel(
            id: 2,
            title: 'Short Story Analysis',
            subject: 'English',
            dueDate: '2026-04-16',
            teacherName: 'Ms. Layla',
            status: 'pending',
            description: 'Write 400 words analysing the themes in "The Gift of the Magi".'),
        const HomeworkModel(
            id: 3,
            title: 'Photosynthesis Summary',
            subject: 'Science',
            dueDate: '2026-04-10',
            teacherName: 'Dr. Nour',
            status: 'submitted',
            description: 'Summarise the light-dependent and light-independent reactions.',
            submittedContent: 'Photosynthesis occurs in two stages...',
            submissionNotes: 'Submitted on time.'),
        const HomeworkModel(
            id: 4,
            title: 'WWI Timeline',
            subject: 'History',
            dueDate: '2026-04-05',
            teacherName: 'Mr. Khaled',
            status: 'graded',
            description: 'Create a detailed timeline of World War I key events.',
            submittedContent: 'Timeline starts 1914...',
            grade: 47,
            gradeFeedback: 'Good detail on major events. Missing the armistice date.'),
        const HomeworkModel(
            id: 5,
            title: 'Fractions Worksheet',
            subject: 'Mathematics',
            dueDate: '2026-04-02',
            teacherName: 'Mr. Ibrahim',
            status: 'late',
            description: 'Complete the fractions worksheet — all 30 questions.'),
      ];

  // ── Attendance ────────────────────────────────────────────────────────────
  static AttendanceSummaryModel get attendance {
    final records = <AttendanceRecordModel>[];
    final now = DateTime.now();
    final statuses = ['present', 'present', 'present', 'present', 'present',
        'present', 'present', 'late', 'present', 'absent'];
    for (int i = 30; i >= 1; i--) {
      final d = now.subtract(Duration(days: i));
      if (d.weekday <= 5) { // weekdays only
        final s = statuses[i % statuses.length];
        records.add(AttendanceRecordModel(
          date: d.toIso8601String().split('T').first,
          status: s,
        ));
      }
    }
    return AttendanceSummaryModel(
      percent: 91.5,
      present: records.where((r) => r.status == 'present').length,
      absent: records.where((r) => r.status == 'absent').length,
      late: records.where((r) => r.status == 'late').length,
      excused: 0,
      records: records,
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  static List<NotificationModel> get notifications => [
        const NotificationModel(id: 1, recipientId: 1, title: 'Exam schedule published', body: 'Final exams start May 5th. Check the portal for your timetable.', isRead: false, createdAt: '2026-04-11T09:00:00Z'),
        const NotificationModel(id: 2, recipientId: 2, title: 'School holiday — April 18', body: 'School will be closed on April 18 for a national holiday.', isRead: false, createdAt: '2026-04-10T14:00:00Z'),
        const NotificationModel(id: 3, recipientId: 3, title: 'Parent meeting — April 20', body: 'Parent-teacher meetings will take place on April 20 from 4–7 PM.', isRead: true, createdAt: '2026-04-09T08:30:00Z'),
        const NotificationModel(id: 4, recipientId: 4, title: 'Library books due', isRead: true, createdAt: '2026-04-08T10:00:00Z'),
      ];

  static List<NotificationModel> get warnings => [
        NotificationModel(id: 10, recipientId: 10, title: 'Late arrival — April 9', body: 'You arrived 20 minutes late on April 9. Three late arrivals result in a formal warning.', isRead: false, createdAt: '2026-04-09T07:50:00Z', isWarning: true),
        NotificationModel(id: 11, recipientId: 11, title: 'Missing homework — Fractions Worksheet', body: 'You did not submit the Fractions Worksheet due April 2.', isRead: true, createdAt: '2026-04-03T09:00:00Z', isWarning: true),
      ];

  // ── Bus ───────────────────────────────────────────────────────────────────
  static const busAssignment = BusAssignmentModel(
    busPlate: 'SB-1234',
    routeName: 'Route A — North District',
    pickupStopName: 'Main Gate',
    stops: [
      BusStopModel(id: 1, name: 'Main Gate', order: 1),
      BusStopModel(id: 2, name: 'Park Avenue', order: 2),
      BusStopModel(id: 3, name: 'Central Square', order: 3),
      BusStopModel(id: 4, name: 'School', order: 4),
    ],
  );

  static const busLiveLocation = BusLiveLocationModel(
    latitude: 33.513,
    longitude: 36.312,
    driverName: 'Ahmed Hassan',
    routeName: 'Route A — North District',
    updatedAt: '2026-04-12T07:42:00Z',
  );

  static List<BusEventModel> get busEvents => [
        const BusEventModel(id: 1, date: '2026-04-12', stopName: 'Main Gate', eventType: 'boarded', time: '07:15'),
        const BusEventModel(id: 2, date: '2026-04-12', stopName: 'School', eventType: 'dropped', time: '07:55'),
        const BusEventModel(id: 3, date: '2026-04-11', stopName: 'Main Gate', eventType: 'boarded', time: '07:18'),
        const BusEventModel(id: 4, date: '2026-04-11', stopName: 'School', eventType: 'dropped', time: '07:58'),
        const BusEventModel(id: 5, date: '2026-04-10', stopName: 'Main Gate', eventType: 'boarded', time: '07:14'),
        const BusEventModel(id: 6, date: '2026-04-10', stopName: 'School', eventType: 'dropped', time: '07:54'),
      ];
}
