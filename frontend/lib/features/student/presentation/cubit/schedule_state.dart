import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();
  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {}
class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleSlotModel> slots;
  final String selectedDay; // e.g. 'monday'

  const ScheduleLoaded({required this.slots, required this.selectedDay});

  ScheduleLoaded copyWith({List<ScheduleSlotModel>? slots, String? selectedDay}) =>
      ScheduleLoaded(
        slots: slots ?? this.slots,
        selectedDay: selectedDay ?? this.selectedDay,
      );

  List<ScheduleSlotModel> get slotsForDay =>
      slots.where((s) => s.day == selectedDay).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  List<Object?> get props => [slots, selectedDay];
}

class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);
  @override
  List<Object?> get props => [message];
}
