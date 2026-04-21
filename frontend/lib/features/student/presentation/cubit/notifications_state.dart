import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final List<NotificationModel> warnings;

  const NotificationsLoaded({
    required this.notifications,
    required this.warnings,
  });

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    List<NotificationModel>? warnings,
  }) =>
      NotificationsLoaded(
        notifications: notifications ?? this.notifications,
        warnings: warnings ?? this.warnings,
      );

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length +
      warnings.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications, warnings];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}
