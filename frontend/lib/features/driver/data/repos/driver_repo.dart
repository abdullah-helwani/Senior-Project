import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';

// Driver trips endpoints return raw arrays (NOT paginated) per backend doc.
// _toList handles both just in case.
List<dynamic> _toList(dynamic res) {
  if (res is List<dynamic>) return res;
  if (res is Map<String, dynamic>) {
    final data = res['data'];
    if (data is List<dynamic>) return data;
  }
  return const [];
}

class DriverRepo {
  final ApiConsumer api;

  DriverRepo({required this.api});

  Future<DriverProfileModel> getProfile(int driverId) async {
    final res = await api.getApi(AppUrl.driverProfile(driverId));
    return DriverProfileModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<TripSummaryModel>> getTodayTrips(int driverId) async {
    final res = await api.getApi(AppUrl.driverTripsToday(driverId));
    return _toList(res)
        .map((t) => TripSummaryModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<List<TripSummaryModel>> getTripHistory(
    int driverId, {
    DateTime? from,
    DateTime? to,
    String? period,
  }) async {
    final res = await api.getApi(
      AppUrl.driverTrips(driverId),
      queryParameters: {
        if (from != null) 'from': from.toIso8601String().split('T').first,
        if (to != null) 'to': to.toIso8601String().split('T').first,
        if (period != null) 'period': period,
      },
    );
    return _toList(res)
        .map((t) => TripSummaryModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<TripDetailModel> getTripDetail(int driverId, int tripId) async {
    final res = await api.getApi(AppUrl.driverTrip(driverId, tripId));
    return TripDetailModel.fromJson(res as Map<String, dynamic>);
  }

  Future<void> postStopEvent({
    required int driverId,
    required int tripId,
    required int stopId,
    required int studentId,
    required String eventType, // 'boarded' | 'dropped'
  }) async {
    await api.post(
      AppUrl.driverStopEvents(driverId, tripId),
      data: {
        'stop_id': stopId,
        'student_id': studentId,
        'event_type': eventType,
      },
    );
  }

  Future<void> pingLocation({
    required int driverId,
    required int tripId,
    required double latitude,
    required double longitude,
  }) async {
    await api.post(
      AppUrl.driverPings(driverId, tripId),
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }
}
