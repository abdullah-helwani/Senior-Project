import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TeacherAvailabilityState extends Equatable {
  const TeacherAvailabilityState();
  @override
  List<Object?> get props => [];
}

class TeacherAvailabilityInitial extends TeacherAvailabilityState {
  const TeacherAvailabilityInitial();
}

class TeacherAvailabilityLoading extends TeacherAvailabilityState {
  const TeacherAvailabilityLoading();
}

class TeacherAvailabilityLoaded extends TeacherAvailabilityState {
  final List<TeacherAvailabilityModel> slots;
  final String? dayFilter;
  final bool working; // true while adding/updating/deleting

  const TeacherAvailabilityLoaded({
    required this.slots,
    this.dayFilter,
    this.working = false,
  });

  TeacherAvailabilityLoaded copyWith({
    List<TeacherAvailabilityModel>? slots,
    String? dayFilter,
    bool clearDay = false,
    bool? working,
  }) =>
      TeacherAvailabilityLoaded(
        slots: slots ?? this.slots,
        dayFilter: clearDay ? null : (dayFilter ?? this.dayFilter),
        working: working ?? this.working,
      );

  @override
  List<Object?> get props => [slots, dayFilter, working];
}

class TeacherAvailabilityError extends TeacherAvailabilityState {
  final String message;
  const TeacherAvailabilityError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherAvailabilityCubit extends Cubit<TeacherAvailabilityState> {
  final TeacherRepo repo;

  TeacherAvailabilityCubit({required this.repo})
      : super(const TeacherAvailabilityInitial());

  Future<void> load({String? dayOfWeek}) async {
    emit(const TeacherAvailabilityLoading());
    try {
      final slots = await repo.getAvailability(dayOfWeek: dayOfWeek);
      emit(TeacherAvailabilityLoaded(slots: slots, dayFilter: dayOfWeek));
    } catch (e) {
      emit(TeacherAvailabilityError(e.toString()));
    }
  }

  Future<bool> add({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String type,
  }) async {
    final s = state;
    final base = s is TeacherAvailabilityLoaded
        ? s
        : const TeacherAvailabilityLoaded(slots: []);
    emit(base.copyWith(working: true));
    try {
      final created = await repo.createAvailability(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        type: type,
      );
      emit(base.copyWith(slots: [...base.slots, created], working: false));
      return true;
    } catch (e) {
      emit(base.copyWith(working: false));
      emit(TeacherAvailabilityError(e.toString()));
      return false;
    }
  }

  Future<bool> update(
    int slotId, {
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? type,
  }) async {
    final s = state;
    if (s is! TeacherAvailabilityLoaded) return false;
    emit(s.copyWith(working: true));
    try {
      final updated = await repo.updateAvailability(
        slotId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        type: type,
      );
      emit(s.copyWith(
        slots: s.slots.map((x) => x.id == slotId ? updated : x).toList(),
        working: false,
      ));
      return true;
    } catch (e) {
      emit(s.copyWith(working: false));
      emit(TeacherAvailabilityError(e.toString()));
      return false;
    }
  }

  Future<bool> remove(int slotId) async {
    final s = state;
    if (s is! TeacherAvailabilityLoaded) return false;
    emit(s.copyWith(working: true));
    try {
      await repo.deleteAvailability(slotId);
      emit(s.copyWith(
        slots: s.slots.where((x) => x.id != slotId).toList(),
        working: false,
      ));
      return true;
    } catch (e) {
      emit(s.copyWith(working: false));
      emit(TeacherAvailabilityError(e.toString()));
      return false;
    }
  }
}
