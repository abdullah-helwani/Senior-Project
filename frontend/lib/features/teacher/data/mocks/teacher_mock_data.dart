import 'package:first_try/features/teacher/data/models/teacher_models.dart';

class TeacherMockData {
  // ── Dashboard ────────────────────────────────────────────────────────────
  static const dashboard = TeacherDashboardModel(
    name: 'Mr. Ibrahim',
    todayClassesCount: 4,
    pendingGradingCount: 7,
    unreadNotificationsCount: 2,
    totalStudents: 92,
  );

  // ── Profile ──────────────────────────────────────────────────────────────
  static const profile = TeacherProfileModel(
    id: 1,
    name: 'Mr. Ibrahim Al-Hassan',
    email: 'ibrahim@school.com',
    phone: '+963 911 222 333',
    subject: 'Mathematics',
    qualification: 'M.Sc. Mathematics — Damascus University',
    schoolYear: '2025 – 2026',
    classCount: 4,
  );

  // ── Schedule ─────────────────────────────────────────────────────────────
  static List<TeacherScheduleSlotModel> get schedule => [
        // Monday
        const TeacherScheduleSlotModel(id: 1,  day: 'monday',    startTime: '07:30', endTime: '08:15', className: 'Grade 9A', subject: 'Mathematics', order: 1),
        const TeacherScheduleSlotModel(id: 2,  day: 'monday',    startTime: '08:20', endTime: '09:05', className: 'Grade 9B', subject: 'Mathematics', order: 2),
        const TeacherScheduleSlotModel(id: 3,  day: 'monday',    startTime: '10:10', endTime: '10:55', className: 'Grade 10A', subject: 'Mathematics', order: 3),
        // Tuesday
        const TeacherScheduleSlotModel(id: 4,  day: 'tuesday',   startTime: '08:20', endTime: '09:05', className: 'Grade 9A', subject: 'Mathematics', order: 1),
        const TeacherScheduleSlotModel(id: 5,  day: 'tuesday',   startTime: '09:10', endTime: '09:55', className: 'Grade 10B', subject: 'Mathematics', order: 2),
        // Wednesday
        const TeacherScheduleSlotModel(id: 6,  day: 'wednesday', startTime: '07:30', endTime: '08:15', className: 'Grade 10A', subject: 'Mathematics', order: 1),
        const TeacherScheduleSlotModel(id: 7,  day: 'wednesday', startTime: '08:20', endTime: '09:05', className: 'Grade 9B', subject: 'Mathematics', order: 2),
        const TeacherScheduleSlotModel(id: 8,  day: 'wednesday', startTime: '11:00', endTime: '11:45', className: 'Grade 9A', subject: 'Mathematics', order: 3),
        // Thursday
        const TeacherScheduleSlotModel(id: 9,  day: 'thursday',  startTime: '09:10', endTime: '09:55', className: 'Grade 10B', subject: 'Mathematics', order: 1),
        const TeacherScheduleSlotModel(id: 10, day: 'thursday',  startTime: '10:10', endTime: '10:55', className: 'Grade 10A', subject: 'Mathematics', order: 2),
      ];

  // ── Classes ───────────────────────────────────────────────────────────────
  static List<TeacherClassModel> get classes => [
        const TeacherClassModel(
          id: 1,
          name: 'Grade 9A',
          subject: 'Mathematics',
          students: [
            ClassStudentModel(id: 1,  name: 'Omar Khalid',     averageScore: 85.0, attendancePercent: 91.5),
            ClassStudentModel(id: 2,  name: 'Sara Ahmed',      averageScore: 92.0, attendancePercent: 97.0),
            ClassStudentModel(id: 3,  name: 'Ali Hassan',      averageScore: 74.5, attendancePercent: 88.0),
            ClassStudentModel(id: 4,  name: 'Nour Mustafa',    averageScore: 88.0, attendancePercent: 95.0),
            ClassStudentModel(id: 5,  name: 'Layla Saleh',     averageScore: 79.0, attendancePercent: 93.0),
            ClassStudentModel(id: 6,  name: 'Rami Kareem',     averageScore: 65.0, attendancePercent: 82.0),
          ],
        ),
        const TeacherClassModel(
          id: 2,
          name: 'Grade 9B',
          subject: 'Mathematics',
          students: [
            ClassStudentModel(id: 7,  name: 'Hana Farouk',     averageScore: 90.0, attendancePercent: 99.0),
            ClassStudentModel(id: 8,  name: 'Youssef Nader',   averageScore: 78.0, attendancePercent: 87.0),
            ClassStudentModel(id: 9,  name: 'Dina Walid',      averageScore: 83.0, attendancePercent: 91.0),
            ClassStudentModel(id: 10, name: 'Khaled Tarek',    averageScore: 71.0, attendancePercent: 85.0),
            ClassStudentModel(id: 11, name: 'Maya Ibrahim',    averageScore: 95.0, attendancePercent: 100.0),
          ],
        ),
        const TeacherClassModel(
          id: 3,
          name: 'Grade 10A',
          subject: 'Mathematics',
          students: [
            ClassStudentModel(id: 12, name: 'Faris Amin',      averageScore: 88.0, attendancePercent: 94.0),
            ClassStudentModel(id: 13, name: 'Rana Sami',       averageScore: 76.0, attendancePercent: 89.0),
            ClassStudentModel(id: 14, name: 'Ziad Bassam',     averageScore: 91.0, attendancePercent: 96.0),
            ClassStudentModel(id: 15, name: 'Lina Jaber',      averageScore: 69.0, attendancePercent: 80.0),
          ],
        ),
        const TeacherClassModel(
          id: 4,
          name: 'Grade 10B',
          subject: 'Mathematics',
          students: [
            ClassStudentModel(id: 16, name: 'Samer Rifai',     averageScore: 82.0, attendancePercent: 92.0),
            ClassStudentModel(id: 17, name: 'Tala Mousa',      averageScore: 87.0, attendancePercent: 95.0),
            ClassStudentModel(id: 18, name: 'Nabil Khoury',    averageScore: 73.0, attendancePercent: 86.0),
          ],
        ),
      ];

  // ── Homework ──────────────────────────────────────────────────────────────
  static List<TeacherHomeworkModel> get homework => [
        const TeacherHomeworkModel(
          id: 1,
          title: 'Algebra Exercises — Ch. 4',
          subject: 'Mathematics',
          className: 'Grade 9A',
          dueDate: '2026-04-15',
          description: 'Complete exercises 1–20 on page 87. Show all working.',
          status: 'published',
          submissionCount: 4,
          totalStudents: 6,
        ),
        const TeacherHomeworkModel(
          id: 2,
          title: 'Fractions Worksheet',
          subject: 'Mathematics',
          className: 'Grade 9A',
          dueDate: '2026-04-02',
          description: 'Complete all 30 questions on the fractions worksheet.',
          status: 'published',
          submissionCount: 6,
          totalStudents: 6,
        ),
        const TeacherHomeworkModel(
          id: 3,
          title: 'Quadratic Equations — Practice',
          subject: 'Mathematics',
          className: 'Grade 10A',
          dueDate: '2026-04-18',
          description: 'Solve problems 1–15. Use the quadratic formula where needed.',
          status: 'published',
          submissionCount: 2,
          totalStudents: 4,
        ),
        const TeacherHomeworkModel(
          id: 4,
          title: 'Trigonometry Intro',
          subject: 'Mathematics',
          className: 'Grade 10B',
          dueDate: '2026-04-20',
          description: 'Read chapter 6 and answer review questions.',
          status: 'draft',
          submissionCount: 0,
          totalStudents: 3,
        ),
      ];

  // ── Homework submissions (for hw id=1) ────────────────────────────────────
  static List<HomeworkSubmissionModel> get submissionsHw1 => [
        const HomeworkSubmissionModel(
          id: 1, studentId: 1, studentName: 'Omar Khalid',
          submittedAt: '2026-04-13T14:22:00Z',
          content: 'Exercise 1: x=3, Exercise 2: x=7...',
          status: 'submitted',
        ),
        const HomeworkSubmissionModel(
          id: 2, studentId: 2, studentName: 'Sara Ahmed',
          submittedAt: '2026-04-13T10:05:00Z',
          content: 'All solutions with detailed working shown.',
          grade: 18, feedback: 'Excellent work!',
          status: 'graded',
        ),
        const HomeworkSubmissionModel(
          id: 3, studentId: 3, studentName: 'Ali Hassan',
          submittedAt: '2026-04-14T08:00:00Z',
          content: 'Partial solutions...',
          status: 'submitted',
        ),
        const HomeworkSubmissionModel(
          id: 4, studentId: 4, studentName: 'Nour Mustafa',
          submittedAt: '2026-04-12T19:30:00Z',
          content: 'Complete solutions with graphs.',
          grade: 20, feedback: 'Perfect!',
          status: 'graded',
        ),
        const HomeworkSubmissionModel(
          id: 5, studentId: 5, studentName: 'Layla Saleh',
          status: 'pending',
        ),
        const HomeworkSubmissionModel(
          id: 6, studentId: 6, studentName: 'Rami Kareem',
          status: 'pending',
        ),
      ];

  // ── Attendance sessions ───────────────────────────────────────────────────
  static List<TeacherAttendanceSessionModel> get attendanceSessions => [
        TeacherAttendanceSessionModel(
          id: 1,
          date: '2026-04-13',
          className: 'Grade 9A',
          subject: 'Mathematics',
          status: 'pending',
          entries: const [
            AttendanceEntryModel(studentId: 1, studentName: 'Omar Khalid',  status: 'present'),
            AttendanceEntryModel(studentId: 2, studentName: 'Sara Ahmed',   status: 'present'),
            AttendanceEntryModel(studentId: 3, studentName: 'Ali Hassan',   status: 'absent'),
            AttendanceEntryModel(studentId: 4, studentName: 'Nour Mustafa', status: 'present'),
            AttendanceEntryModel(studentId: 5, studentName: 'Layla Saleh',  status: 'late'),
            AttendanceEntryModel(studentId: 6, studentName: 'Rami Kareem',  status: 'present'),
          ],
        ),
        TeacherAttendanceSessionModel(
          id: 2,
          date: '2026-04-13',
          className: 'Grade 9B',
          subject: 'Mathematics',
          status: 'pending',
          entries: const [
            AttendanceEntryModel(studentId: 7,  studentName: 'Hana Farouk',   status: 'present'),
            AttendanceEntryModel(studentId: 8,  studentName: 'Youssef Nader', status: 'present'),
            AttendanceEntryModel(studentId: 9,  studentName: 'Dina Walid',    status: 'present'),
            AttendanceEntryModel(studentId: 10, studentName: 'Khaled Tarek',  status: 'absent'),
            AttendanceEntryModel(studentId: 11, studentName: 'Maya Ibrahim',  status: 'present'),
          ],
        ),
        TeacherAttendanceSessionModel(
          id: 3,
          date: '2026-04-12',
          className: 'Grade 10A',
          subject: 'Mathematics',
          status: 'submitted',
          entries: const [
            AttendanceEntryModel(studentId: 12, studentName: 'Faris Amin',  status: 'present'),
            AttendanceEntryModel(studentId: 13, studentName: 'Rana Sami',   status: 'present'),
            AttendanceEntryModel(studentId: 14, studentName: 'Ziad Bassam', status: 'late'),
            AttendanceEntryModel(studentId: 15, studentName: 'Lina Jaber',  status: 'absent'),
          ],
        ),
        TeacherAttendanceSessionModel(
          id: 4,
          date: '2026-04-11',
          className: 'Grade 9A',
          subject: 'Mathematics',
          status: 'submitted',
          entries: const [
            AttendanceEntryModel(studentId: 1, studentName: 'Omar Khalid',  status: 'present'),
            AttendanceEntryModel(studentId: 2, studentName: 'Sara Ahmed',   status: 'present'),
            AttendanceEntryModel(studentId: 3, studentName: 'Ali Hassan',   status: 'present'),
            AttendanceEntryModel(studentId: 4, studentName: 'Nour Mustafa', status: 'present'),
            AttendanceEntryModel(studentId: 5, studentName: 'Layla Saleh',  status: 'present'),
            AttendanceEntryModel(studentId: 6, studentName: 'Rami Kareem',  status: 'absent'),
          ],
        ),
      ];

  // ── Notifications ─────────────────────────────────────────────────────────
  static List<TeacherNotificationModel> get notifications => [
        const TeacherNotificationModel(
          id: 1, title: 'Staff meeting — April 15',
          body: 'Mandatory staff meeting on April 15 at 2 PM in the conference room.',
          isRead: false, createdAt: '2026-04-12T08:00:00Z',
        ),
        const TeacherNotificationModel(
          id: 2, title: 'Grade submission deadline',
          body: 'Final grades for Q3 must be submitted by April 20.',
          isRead: false, createdAt: '2026-04-11T09:30:00Z',
        ),
        const TeacherNotificationModel(
          id: 3, title: 'New student added to Grade 9A',
          body: 'A new student, Karim Adel, has been added to your Grade 9A class.',
          isRead: true, createdAt: '2026-04-10T11:00:00Z',
        ),
        const TeacherNotificationModel(
          id: 4, title: 'Exam schedule published',
          body: 'Final exam schedule is now available. Please review your invigilation duties.',
          isRead: true, createdAt: '2026-04-09T14:00:00Z',
        ),
      ];
}
