import 'package:equatable/equatable.dart';
import 'package:first_try/features/student/data/models/student_models.dart';

abstract class BusState extends Equatable {
  const BusState();
  @override
  List<Object?> get props => [];
}

class BusInitial extends BusState {}
class BusLoading extends BusState {}

class BusLoaded extends BusState {
  final BusAssignmentModel assignment;
  final BusLiveLocationModel? liveLocation;
  final List<BusEventModel> events;

  const BusLoaded({
    required this.assignment,
    this.liveLocation,
    required this.events,
  });

  BusLoaded copyWith({
    BusAssignmentModel? assignment,
    BusLiveLocationModel? liveLocation,
    List<BusEventModel>? events,
  }) =>
      BusLoaded(
        assignment: assignment ?? this.assignment,
        liveLocation: liveLocation ?? this.liveLocation,
        events: events ?? this.events,
      );

  @override
  List<Object?> get props => [assignment, liveLocation, events];
}

class BusError extends BusState {
  final String message;
  const BusError(this.message);
  @override
  List<Object?> get props => [message];
}
