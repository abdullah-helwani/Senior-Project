import 'package:equatable/equatable.dart';

/// A single boarded/dropped event on a trip.
/// Backend shape (raw Eloquent):
/// {
///   id, trip_id, stop_id, student_id, eventtype, eventat,
///   stop: { stop_id, name, ... },
///   student: { id, user: { name } }
/// }
///
/// NOTE: Backend field is `eventtype` (no underscore) — keep this when sending
/// a new event. See DriverRepo.postStopEvent.
class TripStopEventModel extends Equatable {
  final int id;
  final int tripId;
  final int stopId;
  final int studentId;
  final String eventType; // boarded / dropped
  final String eventAt;

  final String? stopName;
  final String? studentName;

  const TripStopEventModel({
    required this.id,
    required this.tripId,
    required this.stopId,
    required this.studentId,
    required this.eventType,
    required this.eventAt,
    this.stopName,
    this.studentName,
  });

  bool get isBoarded => eventType == 'boarded';
  bool get isDropped => eventType == 'dropped';

  factory TripStopEventModel.fromJson(Map<String, dynamic> json) {
    final stop = json['stop'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final studentUser =
        student == null ? null : student['user'] as Map<String, dynamic>?;

    return TripStopEventModel(
      id: (json['id'] ?? json['event_id']) as int,
      tripId: json['trip_id'] as int,
      stopId: json['stop_id'] as int,
      studentId: json['student_id'] as int,
      eventType: (json['eventtype'] as String?) ?? 'boarded',
      eventAt: (json['eventat'] as String?) ?? '',
      stopName: stop?['name'] as String?,
      studentName: (studentUser?['name'] ?? student?['name']) as String?,
    );
  }

  @override
  List<Object?> get props => [id, tripId, stopId, studentId, eventType, eventAt];
}
