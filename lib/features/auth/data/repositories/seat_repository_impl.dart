import '../../domain/entities/reservation.dart';
import '../../domain/entities/seat_map.dart';
import '../../domain/repositories/seat_repository.dart';
import '../datasources/seat_data_source.dart';

class SeatRepositoryImpl implements SeatRepository {
  final SeatDataSource dataSource;
  SeatRepositoryImpl(this.dataSource);

  // لا نلتقط الأخطاء هنا: تصل كما هي (ApiException) إلى الـ Cubit
  @override
  Future<SeatMap> getSeatMap(int tripId) => dataSource.fetchSeatMap(tripId);

  @override
  Future<Reservation> reserveSeats(int tripId, List<int> seatIds) =>
      dataSource.reserveSeats(tripId, seatIds);

  @override
  Future<void> confirmBooking(int bookingId, String paymentReference) =>
      dataSource.confirmBooking(bookingId, paymentReference);

  @override
  Future<void> cancelBooking(int bookingId) =>
      dataSource.cancelBooking(bookingId);
}
