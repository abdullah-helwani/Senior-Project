import 'package:equatable/equatable.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';

abstract class TripHistoryState extends Equatable {
  const TripHistoryState();
  @override
  List<Object?> get props => [];
}

class TripHistoryInitial extends TripHistoryState {
  const TripHistoryInitial();
}

class TripHistoryLoading extends TripHistoryState {
  const TripHistoryLoading();
}

class TripHistoryLoaded extends TripHistoryState {
  final List<TripSummaryModel> trips;
  const TripHistoryLoaded({required this.trips});
  @override
  List<Object> get props => [trips];
}

class TripHistoryError extends TripHistoryState {
  final String message;
  const TripHistoryError({required this.message});
  @override
  List<Object> get props => [message];
}
