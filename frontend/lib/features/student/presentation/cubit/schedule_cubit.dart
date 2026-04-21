import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/schedule_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final StudentRepo repo;

  ScheduleCubit({required this.repo}) : super(ScheduleInitial());

  Future<void> load() async {
    emit(ScheduleLoading());
    try {
      final slots = await repo.getSchedule();
      emit(ScheduleLoaded(slots: slots, selectedDay: _todayKey()));
    } catch (_) {
      emit(ScheduleLoaded(
        slots: StudentMockData.schedule,
        selectedDay: _todayKey(),
      ));
    }
  }

  void selectDay(String day) {
    final s = state;
    if (s is ScheduleLoaded) {
      emit(s.copyWith(selectedDay: day));
    }
  }

  String _todayKey() {
    const keys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    final idx = DateTime.now().weekday - 1; // Monday=1 → idx=0
    return keys[idx.clamp(0, 6)];
  }
}
