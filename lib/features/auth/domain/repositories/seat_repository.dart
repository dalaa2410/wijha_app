import '../entities/reservation.dart';
import '../entities/seat_map.dart';

abstract class SeatRepository {
  Future<SeatMap> getSeatMap(int tripId);
  Future<Reservation> reserveSeats(int tripId, List<int> seatIds);
  Future<void> confirmBooking(int bookingId, String paymentReference);
}