import 'package:first_try/features/teacher/data/mocks/teacher_mock_data.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherDashboardCubit extends Cubit<TeacherDashboardState> {
  final TeacherRepo repo;
  TeacherDashboardCubit({required this.repo}) : super(TeacherDashboardInitial());

  Future<void> load() async {
    emit(TeacherDashboardLoading());
    try {
      // No dedicated dashboard endpoint — always falls back to mock.
      await repo.getProfile();
      throw Exception('No dashboard endpoint');
    } catch (_) {
      emit(TeacherDashboardLoaded(TeacherMockData.dashboard));
    }
  }
}
