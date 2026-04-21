import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherClassesState extends Equatable {
  const TeacherClassesState();
  @override List<Object?> get props => [];
}
class TeacherClassesInitial extends TeacherClassesState {}
class TeacherClassesLoading extends TeacherClassesState {}
class TeacherClassesLoaded extends TeacherClassesState {
  final List<TeacherClassModel> classes;
  const TeacherClassesLoaded(this.classes);
  @override List<Object?> get props => [classes];
}
class TeacherClassesError extends TeacherClassesState {
  final String message;
  const TeacherClassesError(this.message);
  @override List<Object?> get props => [message];
}
