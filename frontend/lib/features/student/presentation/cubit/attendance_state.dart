import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}
class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final AttendanceSummaryModel summary;
  const AttendanceLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);
  @override
  List<Object?> get props => [message];
}
