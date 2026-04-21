import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/attendance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final StudentRepo repo;

  AttendanceCubit({required this.repo}) : super(AttendanceInitial());

  Future<void> load() async {
    emit(AttendanceLoading());
    try {
      final data = await repo.getAttendance();
      emit(AttendanceLoaded(data));
    } catch (_) {
      emit(AttendanceLoaded(StudentMockData.attendance));
    }
  }
}
