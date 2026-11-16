import '../../domain/entities/trips_page.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_data_source.dart';

class TripRepositoryImpl implements TripRepository {
  final TripDataSource dataSource;
  TripRepositoryImpl(this.dataSource);

  // لا نلتقط الأخطاء هنا: تصل كما هي (ApiException) إلى الـ Cubit
  @override
  Future<TripsPage> getTrips({
    String? origin,
    String? destination,
    DateTime? date,
    int page = 1,
  }) => dataSource.fetchTrips(
    origin: origin,
    destination: destination,
    date: date,
    page: page,
  );
}
