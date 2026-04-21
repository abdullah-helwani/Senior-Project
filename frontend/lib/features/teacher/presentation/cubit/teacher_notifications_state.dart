import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherNotificationsState extends Equatable {
  const TeacherNotificationsState();
  @override List<Object?> get props => [];
}
class TeacherNotificationsInitial extends TeacherNotificationsState {}
class TeacherNotificationsLoading extends TeacherNotificationsState {}
class TeacherNotificationsLoaded extends TeacherNotificationsState {
  final List<TeacherNotificationModel> notifications;
  const TeacherNotificationsLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  TeacherNotificationsLoaded copyWith({List<TeacherNotificationModel>? notifications}) =>
      TeacherNotificationsLoaded(notifications ?? this.notifications);

  @override List<Object?> get props => [notifications];
}
class TeacherNotificationsError extends TeacherNotificationsState {
  final String message;
  const TeacherNotificationsError(this.message);
  @override List<Object?> get props => [message];
}
