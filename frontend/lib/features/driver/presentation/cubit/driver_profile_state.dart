import 'package:equatable/equatable.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';

abstract class DriverProfileState extends Equatable {
  const DriverProfileState();
  @override
  List<Object?> get props => [];
}

class DriverProfileInitial extends DriverProfileState {
  const DriverProfileInitial();
}

class DriverProfileLoading extends DriverProfileState {
  const DriverProfileLoading();
}

class DriverProfileLoaded extends DriverProfileState {
  final DriverProfileModel profile;
  const DriverProfileLoaded({required this.profile});
  @override
  List<Object> get props => [profile];
}

class DriverProfileError extends DriverProfileState {
  final String message;
  const DriverProfileError({required this.message});
  @override
  List<Object> get props => [message];
}
