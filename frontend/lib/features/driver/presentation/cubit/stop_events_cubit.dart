import 'package:equatable/equatable.dart';
import 'package:first_try/features/driver/data/models/stop_event_model.dart';
import 'package:first_try/features/driver/data/repos/driver_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class StopEventsState extends Equatable {
  const StopEventsState();
  @override
  List<Object?> get props => [];
}

class StopEventsInitial extends StopEventsState {
  const StopEventsInitial();
}

class StopEventsLoading extends StopEventsState {
  const StopEventsLoading();
}

class StopEventsLoaded extends StopEventsState {
  final int driverId;
  final int tripId;
  final List<TripStopEventModel> events;
  final bool working;

  const StopEventsLoaded({
    required this.driverId,
    required this.tripId,
    required this.events,
    this.working = false,
  });

  StopEventsLoaded copyWith({
    List<TripStopEventModel>? events,
    bool? working,
  }) =>
      StopEventsLoaded(
        driverId: driverId,
        tripId: tripId,
        events: events ?? this.events,
        working: working ?? this.working,
      );

  @override
  List<Object?> get props => [driverId, tripId, events, working];
}

class StopEventsError extends StopEventsState {
  final String message;
  const StopEventsError(this.message);
  @override
  List<Object?> get props => [message];
}

class StopEventsCubit extends Cubit<StopEventsState> {
  final DriverRepo repo;
  StopEventsCubit({required this.repo}) : super(const StopEventsInitial());

  Future<void> load({required int driverId, required int tripId}) async {
    emit(const StopEventsLoading());
    try {
      final events = await repo.getStopEvents(driverId, tripId);
      emit(StopEventsLoaded(
        driverId: driverId,
        tripId: tripId,
        events: events,
      ));
    } catch (e) {
      emit(StopEventsError(e.toString()));
    }
  }

  Future<bool> board({required int stopId, required int studentId}) =>
      _post(stopId: stopId, studentId: studentId, eventType: 'boarded');

  Future<bool> drop({required int stopId, required int studentId}) =>
      _post(stopId: stopId, studentId: studentId, eventType: 'dropped');

  Future<bool> _post({
    required int stopId,
    required int studentId,
    required String eventType,
  }) async {
    final s = state;
    if (s is! StopEventsLoaded) return false;
    emit(s.copyWith(working: true));
    try {
      final created = await repo.postStopEvent(
        driverId: s.driverId,
        tripId: s.tripId,
        stopId: stopId,
        studentId: studentId,
        eventType: eventType,
      );
      emit(s.copyWith(events: [...s.events, created], working: false));
      return true;
    } catch (e) {
      emit(s.copyWith(working: false));
      emit(StopEventsError(e.toString()));
      return false;
    }
  }
}
