import 'package:first_try/features/teacher/data/mocks/teacher_mock_data.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherDashboardCubit extends Cubit<TeacherDashboardState> {
  final TeacherRepo repo;
  TeacherDashboardCubit({required this.repo}) : super(TeacherDashboardInitial());

  Future<void> load() async {
    emit(TeacherDashboardLoading());
    try {
      final results = await Future.wait([
        repo.getProfile(),
        repo.getSchedule(),
        repo.getClasses(),
        repo.getHomework(),
        repo.getNotifications(),
      ]);
      final profile = results[0] as TeacherProfileModel;
      final slots   = results[1] as List<TeacherScheduleSlotModel>;
      final classes = results[2] as List<TeacherClassModel>;
      final homework = results[3] as List<TeacherHomeworkModel>;
      final notifications = results[4] as List<TeacherNotificationModel>;

      final todayKey = _todayKey();
      final todayCount = slots
          .where((s) => s.day.toLowerCase() == todayKey)
          .length;

      // Total unique students across the teacher's classes
      final studentIds = <int>{};
      for (final c in classes) {
        for (final s in c.students) {
          studentIds.add(s.id);
        }
      }

      // Pending = sum of (enrolled - submitted) for past-due homework
      final today = DateTime.now();
      int pending = 0;
      for (final hw in homework) {
        final due = DateTime.tryParse(hw.dueDate);
        if (due == null || due.isAfter(today)) continue;
        final missing = hw.totalStudents - hw.submissionCount;
        if (missing > 0) pending += missing;
      }

      final unread = notifications.where((n) => !n.isRead).length;

      emit(TeacherDashboardLoaded(
        TeacherDashboardModel(
          name: profile.name,
          todayClassesCount: todayCount,
          pendingGradingCount: pending,
          unreadNotificationsCount: unread,
          totalStudents: studentIds.length,
        ),
      ));
    } catch (_) {
      emit(TeacherDashboardLoaded(TeacherMockData.dashboard));
    }
  }

  String _todayKey() {
    const keys = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    return keys[(DateTime.now().weekday - 1).clamp(0, 6)];
  }
}
