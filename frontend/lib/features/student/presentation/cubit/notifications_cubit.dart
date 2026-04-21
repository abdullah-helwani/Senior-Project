import 'package:first_try/features/student/data/mocks/student_mock_data.dart';
import 'package:first_try/features/student/data/repos/student_repo.dart';
import 'package:first_try/features/student/presentation/cubit/notifications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final StudentRepo repo;

  NotificationsCubit({required this.repo}) : super(NotificationsInitial());

  Future<void> load() async {
    emit(NotificationsLoading());
    try {
      final notifications = await repo.getNotifications();
      final warnings = await repo.getWarnings();
      emit(NotificationsLoaded(notifications: notifications, warnings: warnings));
    } catch (_) {
      emit(NotificationsLoaded(
        notifications: StudentMockData.notifications,
        warnings: StudentMockData.warnings,
      ));
    }
  }

  Future<void> markRead(int notificationId, {bool isWarning = false}) async {
    final s = state;
    if (s is! NotificationsLoaded) return;

    // Optimistic update
    if (isWarning) {
      final updated = s.warnings
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList();
      emit(s.copyWith(warnings: updated));
    } else {
      final updated = s.notifications
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList();
      emit(s.copyWith(notifications: updated));
    }

    try {
      await repo.markNotificationRead(notificationId);
    } catch (_) {
      // Ignore — optimistic update already applied
    }
  }
}
