import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class MarksState extends Equatable {
  const MarksState();
  @override
  List<Object?> get props => [];
}

class MarksInitial extends MarksState {}
class MarksLoading extends MarksState {}

class MarksLoaded extends MarksState {
  final List<AssessmentModel> marks;
  final MarksSummaryModel summary;
  final String? selectedSubject; // null = all

  const MarksLoaded({
    required this.marks,
    required this.summary,
    this.selectedSubject,
  });

  MarksLoaded copyWith({
    List<AssessmentModel>? marks,
    MarksSummaryModel? summary,
    String? selectedSubject,
    bool clearSubject = false,
  }) =>
      MarksLoaded(
        marks: marks ?? this.marks,
        summary: summary ?? this.summary,
        selectedSubject: clearSubject ? null : (selectedSubject ?? this.selectedSubject),
      );

  @override
  List<Object?> get props => [marks, summary, selectedSubject];
}

class MarksError extends MarksState {
  final String message;
  const MarksError(this.message);
  @override
  List<Object?> get props => [message];
}
