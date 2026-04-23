import 'package:equatable/equatable.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ComplaintsState extends Equatable {
  const ComplaintsState();
  @override
  List<Object?> get props => [];
}

class ComplaintsInitial extends ComplaintsState {
  const ComplaintsInitial();
}

class ComplaintsLoading extends ComplaintsState {
  const ComplaintsLoading();
}

class ComplaintsLoaded extends ComplaintsState {
  final List<ComplaintModel> items;
  final ComplaintModel? opened;
  final String? statusFilter;
  final bool submitting;

  const ComplaintsLoaded({
    required this.items,
    this.opened,
    this.statusFilter,
    this.submitting = false,
  });

  ComplaintsLoaded copyWith({
    List<ComplaintModel>? items,
    ComplaintModel? opened,
    bool clearOpened = false,
    String? statusFilter,
    bool clearFilter = false,
    bool? submitting,
  }) =>
      ComplaintsLoaded(
        items: items ?? this.items,
        opened: clearOpened ? null : (opened ?? this.opened),
        statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
        submitting: submitting ?? this.submitting,
      );

  @override
  List<Object?> get props => [items, opened, statusFilter, submitting];
}

class ComplaintsError extends ComplaintsState {
  final String message;
  const ComplaintsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ComplaintsCubit extends Cubit<ComplaintsState> {
  final ParentRepo repo;

  ComplaintsCubit({required this.repo}) : super(const ComplaintsInitial());

  Future<void> load({String? status}) async {
    emit(const ComplaintsLoading());
    try {
      final items = await repo.getComplaints(status: status);
      emit(ComplaintsLoaded(items: items, statusFilter: status));
    } catch (e) {
      emit(ComplaintsError(e.toString()));
    }
  }

  Future<void> open(int complaintId) async {
    final s = state;
    final base = s is ComplaintsLoaded ? s : const ComplaintsLoaded(items: []);
    emit(base.copyWith(clearOpened: true));
    try {
      final c = await repo.getComplaint(complaintId);
      emit(base.copyWith(opened: c));
    } catch (e) {
      emit(ComplaintsError(e.toString()));
    }
  }

  void closeOpened() {
    final s = state;
    if (s is ComplaintsLoaded) emit(s.copyWith(clearOpened: true));
  }

  Future<bool> submit({
    int? studentId,
    required String subject,
    required String body,
  }) async {
    final s = state;
    final base = s is ComplaintsLoaded ? s : const ComplaintsLoaded(items: []);
    emit(base.copyWith(submitting: true));
    try {
      final created = await repo.submitComplaint(
        studentId: studentId,
        subject: subject,
        body: body,
      );
      emit(base.copyWith(
        items: [created, ...base.items],
        submitting: false,
      ));
      return true;
    } catch (e) {
      emit(base.copyWith(submitting: false));
      emit(ComplaintsError(e.toString()));
      return false;
    }
  }
}
