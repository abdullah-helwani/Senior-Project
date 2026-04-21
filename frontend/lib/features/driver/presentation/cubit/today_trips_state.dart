import 'package:equatable/equatable.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';

abstract class TodayTripsState extends Equatable {
  const TodayTripsState();
  @override
  List<Object?> get props => [];
}

class TodayTripsInitial extends TodayTripsState {
  const TodayTripsInitial();
}

class TodayTripsLoading extends TodayTripsState {
  const TodayTripsLoading();
}

class TodayTripsLoaded extends TodayTripsState {
  final List<TripSummaryModel> trips;
  const TodayTripsLoaded({required this.trips});
  @override
  List<Object> get props => [trips];
}

class TodayTripsError extends TodayTripsState {
  final String message;
  const TodayTripsError({required this.message});
  @override
  List<Object> get props => [message];
}
