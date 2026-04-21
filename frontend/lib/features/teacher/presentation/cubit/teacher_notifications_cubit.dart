import 'package:first_try/features/teacher/data/mocks/teacher_mock_data.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_notifications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherNotificationsCubit extends Cubit<TeacherNotificationsState> {
  final TeacherRepo repo;
  TeacherNotificationsCubit({required this.repo}) : super(TeacherNotificationsInitial());

  Future<void> load() async {
    emit(TeacherNotificationsLoading());
    try {
      emit(TeacherNotificationsLoaded(await repo.getNotifications()));
    } catch (_) {
      emit(TeacherNotificationsLoaded(TeacherMockData.notifications));
    }
  }

  Future<void> markRead(int id) async {
    final s = state;
    if (s is! TeacherNotificationsLoaded) return;
    final updated = s.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    emit(s.copyWith(notifications: updated));
    try { await repo.markNotificationRead(id); } catch (_) {}
  }
}
