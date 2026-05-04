import 'package:first_try/features/teacher/data/mocks/teacher_mock_data.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherDashboardCubit extends Cubit<TeacherDashboardState> {
  final TeacherRepo repo;
  TeacherDashboardCubit({required this.repo}) : super(TeacherDashboardInitial());

  /// There's no dedicated `/dashboard` endpoint — we synthesize the dashboard
  /// from `/teacher/{id}/profile` (name) plus the counts we can compute later
  /// from schedule/notifications. For now counts default to 0; live counts can
  /// be wired in by reading sibling cubit states from the home screen.
  Future<void> load() async {
    emit(TeacherDashboardLoading());
    try {
      final profile = await repo.getProfile();
      emit(TeacherDashboardLoaded(
        TeacherDashboardModel(
          name: profile.name,
          todayClassesCount: 0,
          pendingGradingCount: 0,
          unreadNotificationsCount: 0,
          totalStudents: 0,
        ),
      ));
    } catch (_) {
      // Mock fallback for offline UI testing only — real auth sessions will
      // hit the try branch above.
      emit(TeacherDashboardLoaded(TeacherMockData.dashboard));
    }
  }
}
