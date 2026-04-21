import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherAttendanceState extends Equatable {
  const TeacherAttendanceState();
  @override List<Object?> get props => [];
}
class TeacherAttendanceInitial extends TeacherAttendanceState {}
class TeacherAttendanceLoading extends TeacherAttendanceState {}
class TeacherAttendanceLoaded extends TeacherAttendanceState {
  final List<TeacherAttendanceSessionModel> sessions;
  const TeacherAttendanceLoaded(this.sessions);

  TeacherAttendanceLoaded copyWith({List<TeacherAttendanceSessionModel>? sessions}) =>
      TeacherAttendanceLoaded(sessions ?? this.sessions);

  @override List<Object?> get props => [sessions];
}
class TeacherAttendanceError extends TeacherAttendanceState {
  final String message;
  const TeacherAttendanceError(this.message);
  @override List<Object?> get props => [message];
}
