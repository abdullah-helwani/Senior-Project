import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TeacherBehaviorState extends Equatable {
  const TeacherBehaviorState();
  @override
  List<Object?> get props => [];
}

class TeacherBehaviorInitial extends TeacherBehaviorState {
  const TeacherBehaviorInitial();
}

class TeacherBehaviorLoading extends TeacherBehaviorState {
  const TeacherBehaviorLoading();
}

class TeacherBehaviorLoaded extends TeacherBehaviorState {
  final List<BehaviorLogModel> logs;
  final BehaviorLogModel? opened;
  final bool submitting;

  // Active filters
  final int? sectionFilter;
  final int? studentFilter;
  final String? typeFilter;

  const TeacherBehaviorLoaded({
    required this.logs,
    this.opened,
    this.submitting = false,
    this.sectionFilter,
    this.studentFilter,
    this.typeFilter,
  });

  TeacherBehaviorLoaded copyWith({
    List<BehaviorLogModel>? logs,
    BehaviorLogModel? opened,
    bool clearOpened = false,
    bool? submitting,
    int? sectionFilter,
    int? studentFilter,
    String? typeFilter,
    bool clearFilters = false,
  }) =>
      TeacherBehaviorLoaded(
        logs: logs ?? this.logs,
        opened: clearOpened ? null : (opened ?? this.opened),
        submitting: submitting ?? this.submitting,
        sectionFilter: clearFilters ? null : (sectionFilter ?? this.sectionFilter),
        studentFilter: clearFilters ? null : (studentFilter ?? this.studentFilter),
        typeFilter: clearFilters ? null : (typeFilter ?? this.typeFilter),
      );

  @override
  List<Object?> get props => [logs, opened, submitting, sectionFilter, studentFilter, typeFilter];
}

class TeacherBehaviorError extends TeacherBehaviorState {
  final String message;
  const TeacherBehaviorError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherBehaviorCubit extends Cubit<TeacherBehaviorState> {
  final TeacherRepo repo;

  TeacherBehaviorCubit({required this.repo})
      : super(const TeacherBehaviorInitial());

  Future<void> load({
    int? sectionId,
    int? studentId,
    String? type,
    String? from,
    String? to,
  }) async {
    emit(const TeacherBehaviorLoading());
    try {
      final logs = await repo.getBehaviorLogs(
        sectionId: sectionId,
        studentId: studentId,
        type: type,
        from: from,
        to: to,
      );
      emit(TeacherBehaviorLoaded(
        logs: logs,
        sectionFilter: sectionId,
        studentFilter: studentId,
        typeFilter: type,
      ));
    } catch (e) {
      emit(TeacherBehaviorError(e.toString()));
    }
  }

  Future<void> open(int logId) async {
    final s = state;
    final base =
        s is TeacherBehaviorLoaded ? s : const TeacherBehaviorLoaded(logs: []);
    emit(base.copyWith(clearOpened: true));
    try {
      final log = await repo.getBehaviorLog(logId);
      emit(base.copyWith(opened: log));
    } catch (e) {
      emit(TeacherBehaviorError(e.toString()));
    }
  }

  void closeOpened() {
    final s = state;
    if (s is TeacherBehaviorLoaded) emit(s.copyWith(clearOpened: true));
  }

  Future<bool> create({
    required int studentId,
    required int sectionId,
    required String type,
    required String title,
    String? description,
    required String date,
    bool notifyParent = false,
  }) async {
    final s = state;
    final base =
        s is TeacherBehaviorLoaded ? s : const TeacherBehaviorLoaded(logs: []);
    emit(base.copyWith(submitting: true));
    try {
      final created = await repo.createBehaviorLog(
        studentId: studentId,
        sectionId: sectionId,
        type: type,
        title: title,
        description: description,
        date: date,
        notifyParent: notifyParent,
      );
      emit(base.copyWith(
        logs: [created, ...base.logs],
        submitting: false,
      ));
      return true;
    } catch (e) {
      emit(base.copyWith(submitting: false));
      emit(TeacherBehaviorError(e.toString()));
      return false;
    }
  }
}
