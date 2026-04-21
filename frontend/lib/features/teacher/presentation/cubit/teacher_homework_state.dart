import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherHomeworkState extends Equatable {
  const TeacherHomeworkState();
  @override List<Object?> get props => [];
}
class TeacherHomeworkInitial extends TeacherHomeworkState {}
class TeacherHomeworkLoading extends TeacherHomeworkState {}
class TeacherHomeworkLoaded extends TeacherHomeworkState {
  final List<TeacherHomeworkModel> homework;
  final Map<int, List<HomeworkSubmissionModel>> submissions;
  final Set<int> loadingSubmissions;

  const TeacherHomeworkLoaded({
    required this.homework,
    this.submissions = const {},
    this.loadingSubmissions = const {},
  });

  TeacherHomeworkLoaded copyWith({
    List<TeacherHomeworkModel>? homework,
    Map<int, List<HomeworkSubmissionModel>>? submissions,
    Set<int>? loadingSubmissions,
  }) =>
      TeacherHomeworkLoaded(
        homework: homework ?? this.homework,
        submissions: submissions ?? this.submissions,
        loadingSubmissions: loadingSubmissions ?? this.loadingSubmissions,
      );

  @override List<Object?> get props => [homework, submissions, loadingSubmissions];
}
class TeacherHomeworkError extends TeacherHomeworkState {
  final String message;
  const TeacherHomeworkError(this.message);
  @override List<Object?> get props => [message];
}
