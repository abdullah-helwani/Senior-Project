import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripSummaryModel  — used in list screens (today / history)
// ─────────────────────────────────────────────────────────────────────────────

class TripSummaryModel extends Equatable {
  final int id;
  final String routeName;
  final String busPlate;

  /// 'morning' | 'afternoon'  — backend field is "type" not "period"
  final String period;

  final DateTime date;
  final int studentCount;

  /// 'scheduled' | 'active' | 'completed'
  final String status;

  const TripSummaryModel({
    required this.id,
    required this.routeName,
    required this.busPlate,
    required this.period,
    required this.date,
    required this.studentCount,
    required this.status,
  });

  factory TripSummaryModel.fromJson(Map<String, dynamic> json) {
    // Backend uses "trip_id" as PK and "type" for morning/afternoon
    final tripMap = (json['trip'] as Map<String, dynamic>?) ?? json;
    return TripSummaryModel(
      id: (tripMap['trip_id'] ?? tripMap['id']) as int,
      routeName: (tripMap['route_name'] ?? '') as String,
      // Backend Bus column is "plate_number"
      busPlate: (tripMap['bus_plate'] ?? tripMap['plate_number'] ?? '') as String,
      // Backend column is "type" not "period"
      period: (tripMap['type'] ?? tripMap['period'] ?? 'morning') as String,
      date: DateTime.parse(tripMap['date'] as String),
      studentCount: (tripMap['student_count'] as int?) ?? 0,
      status: (tripMap['status'] ?? 'scheduled') as String,
    );
  }

  @override
  List<Object> get props =>
      [id, routeName, busPlate, period, date, studentCount, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// StopModel
// ─────────────────────────────────────────────────────────────────────────────

class StopModel extends Equatable {
  final int id;
  final String name;
  final int order;
  final double? latitude;
  final double? longitude;

  const StopModel({
    required this.id,
    required this.name,
    required this.order,
    this.latitude,
    this.longitude,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) => StopModel(
        // Backend PK is "stop_id"
        id: (json['stop_id'] ?? json['id']) as int,
        name: json['name'] as String,
        // Backend column is "stoporder" (camelCase-smashed)
        order: (json['stoporder'] ?? json['order'] ?? 0) as int,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [id, name, order, latitude, longitude];
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentTripModel  — one student's boarding status on a trip
// ─────────────────────────────────────────────────────────────────────────────

class StudentTripModel extends Equatable {
  final int id;
  final String studentName;
  final int stopId;
  final String stopName;

  /// 'not_boarded' | 'boarded' | 'dropped'
  final String status;

  final DateTime? boardedAt;
  final DateTime? droppedAt;

  const StudentTripModel({
    required this.id,
    required this.studentName,
    required this.stopId,
    required this.stopName,
    required this.status,
    this.boardedAt,
    this.droppedAt,
  });

  factory StudentTripModel.fromJson(Map<String, dynamic> json) {
    // Backend TripStopEvent uses "eventat" (camelCase-smashed) for timestamp
    // and "eventtype" for boarded/dropped. We derive boardedAt/droppedAt from events.
    final boardedRaw = json['boarded_at'] ?? json['eventat'];
    final droppedRaw = json['dropped_at'];
    return StudentTripModel(
      id: json['id'] as int,
      studentName: json['student_name'] as String,
      stopId: (json['stop_id'] ?? 0) as int,
      stopName: (json['stop_name'] ?? '') as String,
      status: (json['status'] ?? 'not_boarded') as String,
      boardedAt: boardedRaw != null
          ? DateTime.tryParse(boardedRaw as String)
          : null,
      droppedAt: droppedRaw != null
          ? DateTime.tryParse(droppedRaw as String)
          : null,
    );
  }

  StudentTripModel copyWith({
    String? status,
    DateTime? boardedAt,
    DateTime? droppedAt,
  }) =>
      StudentTripModel(
        id: id,
        studentName: studentName,
        stopId: stopId,
        stopName: stopName,
        status: status ?? this.status,
        boardedAt: boardedAt ?? this.boardedAt,
        droppedAt: droppedAt ?? this.droppedAt,
      );

  @override
  List<Object?> get props =>
      [id, studentName, stopId, stopName, status, boardedAt, droppedAt];
}

// ─────────────────────────────────────────────────────────────────────────────
// TripDetailModel  — full trip data for the detail screen
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailModel extends Equatable {
  final int id;
  final String routeName;
  final String busPlate;
  final String period;
  final DateTime date;
  final String status;
  final List<StopModel> stops;
  final List<StudentTripModel> students;

  const TripDetailModel({
    required this.id,
    required this.routeName,
    required this.busPlate,
    required this.period,
    required this.date,
    required this.status,
    required this.stops,
    required this.students,
  });

  factory TripDetailModel.fromJson(Map<String, dynamic> json) {
    // Backend returns { trip: {...}, students: [...] }
    final tripMap = (json['trip'] as Map<String, dynamic>?) ?? json;
    return TripDetailModel(
      id: (tripMap['trip_id'] ?? tripMap['id']) as int,
      routeName: (tripMap['route_name'] ?? '') as String,
      busPlate: (tripMap['bus_plate'] ?? tripMap['plate_number'] ?? '') as String,
      // Backend column is "type" not "period"
      period: (tripMap['type'] ?? tripMap['period'] ?? 'morning') as String,
      date: DateTime.parse(tripMap['date'] as String),
      status: (tripMap['status'] ?? 'scheduled') as String,
      stops: ((json['stops'] ?? tripMap['stops']) as List<dynamic>? ?? [])
          .map((s) => StopModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      students: ((json['students'] ?? tripMap['students']) as List<dynamic>? ?? [])
          .map((s) => StudentTripModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  TripDetailModel copyWith({
    List<StudentTripModel>? students,
    String? status,
  }) =>
      TripDetailModel(
        id: id,
        routeName: routeName,
        busPlate: busPlate,
        period: period,
        date: date,
        status: status ?? this.status,
        stops: stops,
        students: students ?? this.students,
      );

  @override
  List<Object> get props =>
      [id, routeName, busPlate, period, date, status, stops, students];
}

// ─────────────────────────────────────────────────────────────────────────────
// BusModel + DriverProfileModel
// ─────────────────────────────────────────────────────────────────────────────

class BusModel extends Equatable {
  final int id;
  final String plate;
  final String? model;

  const BusModel({required this.id, required this.plate, this.model});

  factory BusModel.fromJson(Map<String, dynamic> json) => BusModel(
        // Backend PK is "bus_id"
        id: (json['bus_id'] ?? json['id']) as int,
        // Backend column is "plate_number"
        plate: (json['plate_number'] ?? json['plate'] ?? '') as String,
        model: json['model'] as String?,
      );

  @override
  List<Object?> get props => [id, plate, model];
}

class DriverProfileModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String phone;
  final List<BusModel> buses;

  const DriverProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.buses,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    // Backend returns { driver: { id, user: { name, email, phone } }, routes: [...] }
    // Unwrap "driver" and "user" if present, otherwise read top-level fields.
    final driverMap = (json['driver'] as Map<String, dynamic>?) ?? json;
    final userMap = (driverMap['user'] as Map<String, dynamic>?) ?? driverMap;
    // Routes (not "buses") are the bus assignments for this driver
    final routesList = (json['routes'] ?? driverMap['routes'] ?? json['buses'] ?? []) as List<dynamic>;
    return DriverProfileModel(
      id: (driverMap['id'] ?? driverMap['driver_id']) as int,
      name: (userMap['name'] ?? '') as String,
      email: (userMap['email'] ?? '') as String,
      phone: (userMap['phone'] as String?) ?? '',
      buses: routesList
          .map((b) => BusModel.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object> get props => [id, name, email, phone, buses];
}
