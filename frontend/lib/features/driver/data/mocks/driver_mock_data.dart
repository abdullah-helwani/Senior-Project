import 'package:first_try/features/driver/data/models/driver_models.dart';

/// Realistic sample data used while the backend is not yet available.
/// Every cubit falls back to this data when the API call fails.
class DriverMockData {
  static DriverProfileModel get profile => const DriverProfileModel(
        id: 1,
        name: 'Ahmed Hassan',
        email: 'driver@school.com',
        phone: '+963 944 123 456',
        buses: [
          BusModel(id: 1, plate: 'SB-1234', model: 'Toyota Coaster — 2022'),
        ],
      );

  static List<TripSummaryModel> get todayTrips => [
        TripSummaryModel(
          id: 1,
          routeName: 'Route A — North District',
          busPlate: 'SB-1234',
          period: 'morning',
          date: DateTime.now(),
          studentCount: 8,
          status: 'scheduled',
        ),
        TripSummaryModel(
          id: 2,
          routeName: 'Route A — North District',
          busPlate: 'SB-1234',
          period: 'afternoon',
          date: DateTime.now(),
          studentCount: 8,
          status: 'scheduled',
        ),
      ];

  static TripDetailModel get tripDetail => TripDetailModel(
        id: 1,
        routeName: 'Route A — North District',
        busPlate: 'SB-1234',
        period: 'morning',
        date: DateTime.now(),
        status: 'active',
        stops: const [
          StopModel(
              id: 1,
              name: 'Main Gate',
              order: 1,
              latitude: 33.510,
              longitude: 36.310),
          StopModel(
              id: 2,
              name: 'Park Avenue',
              order: 2,
              latitude: 33.515,
              longitude: 36.315),
          StopModel(
              id: 3,
              name: 'Central Square',
              order: 3,
              latitude: 33.520,
              longitude: 36.320),
          StopModel(
              id: 4,
              name: 'School',
              order: 4,
              latitude: 33.525,
              longitude: 36.325),
        ],
        students: const [
          StudentTripModel(
              id: 1,
              studentName: 'Omar Khalid',
              stopId: 1,
              stopName: 'Main Gate',
              status: 'not_boarded'),
          StudentTripModel(
              id: 2,
              studentName: 'Sara Ahmed',
              stopId: 2,
              stopName: 'Park Avenue',
              status: 'not_boarded'),
          StudentTripModel(
              id: 3,
              studentName: 'Ali Hassan',
              stopId: 1,
              stopName: 'Main Gate',
              status: 'not_boarded'),
          StudentTripModel(
              id: 4,
              studentName: 'Fatima Nour',
              stopId: 3,
              stopName: 'Central Square',
              status: 'not_boarded'),
          StudentTripModel(
              id: 5,
              studentName: 'Hana Youssef',
              stopId: 2,
              stopName: 'Park Avenue',
              status: 'not_boarded'),
          StudentTripModel(
              id: 6,
              studentName: 'Kareem Saad',
              stopId: 3,
              stopName: 'Central Square',
              status: 'not_boarded'),
          StudentTripModel(
              id: 7,
              studentName: 'Lina Mohsen',
              stopId: 1,
              stopName: 'Main Gate',
              status: 'not_boarded'),
          StudentTripModel(
              id: 8,
              studentName: 'Yusuf Tarek',
              stopId: 2,
              stopName: 'Park Avenue',
              status: 'not_boarded'),
        ],
      );

  static List<TripSummaryModel> get tripHistory {
    final now = DateTime.now();
    return [
      for (int i = 1; i <= 14; i++)
        TripSummaryModel(
          id: i + 100,
          routeName: 'Route A — North District',
          busPlate: 'SB-1234',
          period: i.isEven ? 'morning' : 'afternoon',
          date: now.subtract(Duration(days: (i / 2).ceil())),
          studentCount: 8,
          status: 'completed',
        ),
    ];
  }
}
