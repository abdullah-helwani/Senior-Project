import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final StudentDashboardModel dashboard;
  const DashboardLoaded(this.dashboard);
  @override
  List<Object?> get props => [dashboard];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
