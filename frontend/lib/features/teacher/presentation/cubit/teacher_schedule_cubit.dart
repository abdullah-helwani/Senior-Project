import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_schedule_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherScheduleCubit extends Cubit<TeacherScheduleState> {
  final TeacherRepo repo;
  TeacherScheduleCubit({required this.repo}) : super(TeacherScheduleInitial());

  Future<void> load() async {
    emit(TeacherScheduleLoading());
    try {
      final slots = await repo.getSchedule();
      emit(TeacherScheduleLoaded(slots: slots, selectedDay: _todayKey()));
    } catch (e) {
      emit(TeacherScheduleError(e.toString()));
    }
  }

  void selectDay(String day) {
    final s = state;
    if (s is TeacherScheduleLoaded) emit(s.copyWith(selectedDay: day));
  }

  String _todayKey() {
    const keys = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    return keys[(DateTime.now().weekday - 1).clamp(0, 6)];
  }
}
