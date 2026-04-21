import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherDashboardState extends Equatable {
  const TeacherDashboardState();
  @override List<Object?> get props => [];
}
class TeacherDashboardInitial extends TeacherDashboardState {}
class TeacherDashboardLoading extends TeacherDashboardState {}
class TeacherDashboardLoaded extends TeacherDashboardState {
  final TeacherDashboardModel dashboard;
  const TeacherDashboardLoaded(this.dashboard);
  @override List<Object?> get props => [dashboard];
}
class TeacherDashboardError extends TeacherDashboardState {
  final String message;
  const TeacherDashboardError(this.message);
  @override List<Object?> get props => [message];
}
