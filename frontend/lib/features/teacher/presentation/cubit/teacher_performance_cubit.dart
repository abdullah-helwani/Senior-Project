import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TeacherPerformanceState extends Equatable {
  const TeacherPerformanceState();
  @override
  List<Object?> get props => [];
}

class TeacherPerformanceInitial extends TeacherPerformanceState {
  const TeacherPerformanceInitial();
}

class TeacherPerformanceLoading extends TeacherPerformanceState {
  const TeacherPerformanceLoading();
}

class TeacherPerformanceLoaded extends TeacherPerformanceState {
  final PerformanceReportModel report;
  final int sectionId;
  final int? subjectId;
  final String? weekOf;

  const TeacherPerformanceLoaded({
    required this.report,
    required this.sectionId,
    this.subjectId,
    this.weekOf,
  });

  @override
  List<Object?> get props => [report, sectionId, subjectId, weekOf];
}

class TeacherPerformanceError extends TeacherPerformanceState {
  final String message;
  const TeacherPerformanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherPerformanceCubit extends Cubit<TeacherPerformanceState> {
  final TeacherRepo repo;

  TeacherPerformanceCubit({required this.repo})
      : super(const TeacherPerformanceInitial());

  Future<void> load({
    required int sectionId,
    int? subjectId,
    String? weekOf,
  }) async {
    emit(const TeacherPerformanceLoading());
    try {
      final report = await repo.getPerformanceReport(
        sectionId: sectionId,
        subjectId: subjectId,
        weekOf: weekOf,
      );
      emit(TeacherPerformanceLoaded(
        report: report,
        sectionId: sectionId,
        subjectId: subjectId,
        weekOf: weekOf,
      ));
    } catch (e) {
      emit(TeacherPerformanceError(e.toString()));
    }
  }
}
