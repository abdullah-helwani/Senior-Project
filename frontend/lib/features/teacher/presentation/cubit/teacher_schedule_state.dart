import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_models.dart';

abstract class TeacherScheduleState extends Equatable {
  const TeacherScheduleState();
  @override List<Object?> get props => [];
}
class TeacherScheduleInitial extends TeacherScheduleState {}
class TeacherScheduleLoading extends TeacherScheduleState {}
class TeacherScheduleLoaded extends TeacherScheduleState {
  final List<TeacherScheduleSlotModel> slots;
  final String selectedDay;

  const TeacherScheduleLoaded({required this.slots, required this.selectedDay});

  TeacherScheduleLoaded copyWith({List<TeacherScheduleSlotModel>? slots, String? selectedDay}) =>
      TeacherScheduleLoaded(
        slots: slots ?? this.slots,
        selectedDay: selectedDay ?? this.selectedDay,
      );

  List<TeacherScheduleSlotModel> get slotsForDay =>
      slots.where((s) => s.day == selectedDay).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override List<Object?> get props => [slots, selectedDay];
}
class TeacherScheduleError extends TeacherScheduleState {
  final String message;
  const TeacherScheduleError(this.message);
  @override List<Object?> get props => [message];
}
