import 'package:equatable/equatable.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';

abstract class TripDetailState extends Equatable {
  const TripDetailState();
  @override
  List<Object?> get props => [];
}

class TripDetailInitial extends TripDetailState {
  const TripDetailInitial();
}

class TripDetailLoading extends TripDetailState {
  const TripDetailLoading();
}

class TripDetailLoaded extends TripDetailState {
  final TripDetailModel trip;
  final bool isGpsActive;
  final DateTime? lastPingAt;

  const TripDetailLoaded({
    required this.trip,
    this.isGpsActive = false,
    this.lastPingAt,
  });

  TripDetailLoaded copyWith({
    TripDetailModel? trip,
    bool? isGpsActive,
    DateTime? lastPingAt,
  }) =>
      TripDetailLoaded(
        trip: trip ?? this.trip,
        isGpsActive: isGpsActive ?? this.isGpsActive,
        lastPingAt: lastPingAt ?? this.lastPingAt,
      );

  @override
  List<Object?> get props => [trip, isGpsActive, lastPingAt];
}

class TripDetailError extends TripDetailState {
  final String message;
  const TripDetailError({required this.message});
  @override
  List<Object> get props => [message];
}
