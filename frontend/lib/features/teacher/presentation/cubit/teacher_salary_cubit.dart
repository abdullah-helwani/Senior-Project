import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TeacherSalaryState extends Equatable {
  const TeacherSalaryState();
  @override
  List<Object?> get props => [];
}

class TeacherSalaryInitial extends TeacherSalaryState {
  const TeacherSalaryInitial();
}

class TeacherSalaryLoading extends TeacherSalaryState {
  const TeacherSalaryLoading();
}

class TeacherSalaryLoaded extends TeacherSalaryState {
  final SalarySummaryModel summary;
  final String? yearFilter;
  final SalaryPaymentModel? opened;

  const TeacherSalaryLoaded({
    required this.summary,
    this.yearFilter,
    this.opened,
  });

  TeacherSalaryLoaded copyWith({
    SalarySummaryModel? summary,
    String? yearFilter,
    bool clearYear = false,
    SalaryPaymentModel? opened,
    bool clearOpened = false,
  }) =>
      TeacherSalaryLoaded(
        summary: summary ?? this.summary,
        yearFilter: clearYear ? null : (yearFilter ?? this.yearFilter),
        opened: clearOpened ? null : (opened ?? this.opened),
      );

  @override
  List<Object?> get props => [summary, yearFilter, opened];
}

class TeacherSalaryError extends TeacherSalaryState {
  final String message;
  const TeacherSalaryError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherSalaryCubit extends Cubit<TeacherSalaryState> {
  final TeacherRepo repo;

  TeacherSalaryCubit({required this.repo})
      : super(const TeacherSalaryInitial());

  Future<void> load({String? year}) async {
    emit(const TeacherSalaryLoading());
    try {
      final summary = await repo.getSalary(year: year);
      emit(TeacherSalaryLoaded(summary: summary, yearFilter: year));
    } catch (e) {
      emit(TeacherSalaryError(e.toString()));
    }
  }

  Future<void> open(int salaryId) async {
    final s = state;
    if (s is! TeacherSalaryLoaded) return;
    emit(s.copyWith(clearOpened: true));
    try {
      final payment = await repo.getSalaryPayment(salaryId);
      emit(s.copyWith(opened: payment));
    } catch (e) {
      emit(TeacherSalaryError(e.toString()));
    }
  }

  void closeOpened() {
    final s = state;
    if (s is TeacherSalaryLoaded) emit(s.copyWith(clearOpened: true));
  }
}
