import '../entities/booking.dart';
import '../entities/payment_session.dart';

abstract class BookingRepository {
  // حجوزاتي (من السجل المحلي حاليًا، ويمكن تبديلها بالباك دون لمس الواجهة)
  Future<List<Booking>> getMyBookings();

  // حجز معلّق لم تنتهِ مهلته لرحلة معينة (لشريط المتابعة في شاشة المقاعد)
  Future<Booking?> getActiveHold({required int tripId});

  Future<Booking?> getBooking(int bookingId);

  Future<void> saveBooking(Booking booking);

  // POST /bookings/{id}/pay: يرجع جلسة الدفع ورابطها
  Future<PaymentSession> startPayment(int bookingId);

  // بعد اكتمال الدفع
  Future<void> markPaid(int bookingId);

  // DELETE /bookings/{id}: يعمل للحجز المعلّق والمدفوع
  Future<void> cancelBooking(int bookingId);
}
