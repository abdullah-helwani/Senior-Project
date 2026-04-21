import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final StudentRepo repo;

  DashboardCubit({required this.repo}) : super(DashboardInitial());

  Future<void> load() async {
    emit(DashboardLoading());
    try {
      // No dedicated dashboard endpoint — profile is the closest approximation.
      // Shape mismatch will throw → mock fallback below.
      await repo.getProfile();
      throw Exception('No dashboard endpoint');
    } catch (_) {
      emit(DashboardLoaded(StudentMockData.dashboard));
    }
  }
}
