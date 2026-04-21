import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class HomeworkState extends Equatable {
  const HomeworkState();
  @override
  List<Object?> get props => [];
}

class HomeworkInitial extends HomeworkState {}
class HomeworkLoading extends HomeworkState {}

class HomeworkLoaded extends HomeworkState {
  final List<HomeworkModel> homework;
  final String? statusFilter; // null = all

  const HomeworkLoaded({required this.homework, this.statusFilter});

  HomeworkLoaded copyWith({
    List<HomeworkModel>? homework,
    String? statusFilter,
    bool clearFilter = false,
  }) =>
      HomeworkLoaded(
        homework: homework ?? this.homework,
        statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      );

  List<HomeworkModel> get filtered => statusFilter == null
      ? homework
      : homework.where((h) => h.status == statusFilter).toList();

  @override
  List<Object?> get props => [homework, statusFilter];
}

class HomeworkError extends HomeworkState {
  final String message;
  const HomeworkError(this.message);
  @override
  List<Object?> get props => [message];
}
