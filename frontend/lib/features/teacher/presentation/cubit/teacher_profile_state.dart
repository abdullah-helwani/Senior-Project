import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherProfileState extends Equatable {
  const TeacherProfileState();
  @override List<Object?> get props => [];
}
class TeacherProfileInitial extends TeacherProfileState {}
class TeacherProfileLoading extends TeacherProfileState {}
class TeacherProfileLoaded extends TeacherProfileState {
  final TeacherProfileModel profile;
  const TeacherProfileLoaded(this.profile);
  @override List<Object?> get props => [profile];
}
class TeacherProfileError extends TeacherProfileState {
  final String message;
  const TeacherProfileError(this.message);
  @override List<Object?> get props => [message];
}
