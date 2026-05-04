import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_attendance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherAttendanceCubit extends Cubit<TeacherAttendanceState> {
  final TeacherRepo repo;
  TeacherAttendanceCubit({required this.repo}) : super(TeacherAttendanceInitial());

  Future<void> load() async {
    emit(TeacherAttendanceLoading());
    try {
      emit(TeacherAttendanceLoaded(await repo.getAttendanceSessions()));
    } catch (e) {
      emit(TeacherAttendanceError(e.toString()));
    }
  }

  void updateEntry(int sessionId, int studentId, String status) {
    final s = state;
    if (s is! TeacherAttendanceLoaded) return;

    final sessions = s.sessions.map((session) {
      if (session.id != sessionId) return session;
      final entries = session.entries
          .map((e) => e.studentId == studentId ? e.copyWith(status: status) : e)
          .toList();
      return session.copyWith(entries: entries);
    }).toList();
    emit(s.copyWith(sessions: sessions));
  }

  Future<void> submitSession(int sessionId) async {
    final s = state;
    if (s is! TeacherAttendanceLoaded) return;

    final session = s.sessions.firstWhere((s) => s.id == sessionId);
    try {
      await repo.submitAttendance(
        sectionId: session.id,
        date: session.date,
        entries: session.entries,
      );
    } catch (_) {
      // Still mark as submitted locally
    }

    final sessions = s.sessions
        .map((s) => s.id == sessionId ? s.copyWith(status: 'submitted') : s)
        .toList();
    emit(s.copyWith(sessions: sessions));
  }
}
