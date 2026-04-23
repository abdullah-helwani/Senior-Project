import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TeacherVacationState extends Equatable {
  const TeacherVacationState();
  @override
  List<Object?> get props => [];
}

class TeacherVacationInitial extends TeacherVacationState {
  const TeacherVacationInitial();
}

class TeacherVacationLoading extends TeacherVacationState {
  const TeacherVacationLoading();
}

class TeacherVacationLoaded extends TeacherVacationState {
  final List<VacationRequestModel> requests;
  final String? statusFilter;
  final bool submitting;

  const TeacherVacationLoaded({
    required this.requests,
    this.statusFilter,
    this.submitting = false,
  });

  TeacherVacationLoaded copyWith({
    List<VacationRequestModel>? requests,
    String? statusFilter,
    bool clearFilter = false,
    bool? submitting,
  }) =>
      TeacherVacationLoaded(
        requests: requests ?? this.requests,
        statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
        submitting: submitting ?? this.submitting,
      );

  @override
  List<Object?> get props => [requests, statusFilter, submitting];
}

class TeacherVacationError extends TeacherVacationState {
  final String message;
  const TeacherVacationError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherVacationCubit extends Cubit<TeacherVacationState> {
  final TeacherRepo repo;

  TeacherVacationCubit({required this.repo})
      : super(const TeacherVacationInitial());

  Future<void> load({String? status}) async {
    emit(const TeacherVacationLoading());
    try {
      final reqs = await repo.getVacationRequests(status: status);
      emit(TeacherVacationLoaded(requests: reqs, statusFilter: status));
    } catch (e) {
      emit(TeacherVacationError(e.toString()));
    }
  }

  Future<bool> submit({
    required String startDate,
    required String endDate,
  }) async {
    final s = state;
    final base = s is TeacherVacationLoaded
        ? s
        : const TeacherVacationLoaded(requests: []);
    emit(base.copyWith(submitting: true));
    try {
      final created = await repo.createVacationRequest(
        startDate: startDate,
        endDate: endDate,
      );
      emit(base.copyWith(
        requests: [created, ...base.requests],
        submitting: false,
      ));
      return true;
    } catch (e) {
      emit(base.copyWith(submitting: false));
      emit(TeacherVacationError(e.toString()));
      return false;
    }
  }

  Future<bool> cancel(int requestId) async {
    final s = state;
    if (s is! TeacherVacationLoaded) return false;
    try {
      await repo.cancelVacationRequest(requestId);
      emit(s.copyWith(
        requests: s.requests.where((r) => r.id != requestId).toList(),
      ));
      return true;
    } catch (e) {
      emit(TeacherVacationError(e.toString()));
      return false;
    }
  }
}
