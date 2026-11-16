import '../entities/trips_page.dart';

abstract class TripRepository {
  Future<TripsPage> getTrips({
    String? origin,
    String? destination,
    DateTime? date,
    int page = 1,
  });
}
