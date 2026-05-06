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
      ]);
      final profile = results[0] as TeacherProfileModel;
      final slots   = results[1] as List<TeacherScheduleSlotModel>;

      final todayKey = _todayKey();
      final todayCount = slots
          .where((s) => s.day.toLowerCase() == todayKey)
          .length;

      emit(TeacherDashboardLoaded(
        TeacherDashboardModel(
          name: profile.name,
          todayClassesCount: todayCount,
          pendingGradingCount: 0,
          unreadNotificationsCount: 0,
          totalStudents: 0,
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
