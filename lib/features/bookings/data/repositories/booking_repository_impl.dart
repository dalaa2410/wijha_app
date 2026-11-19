import '../../domain/entities/booking.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_local_data_source.dart';
import '../datasources/booking_remote_data_source.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remote;
  final BookingLocalDataSource local;
  BookingRepositoryImpl(this.remote, this.local);

  @override
  Future<List<Booking>> getMyBookings() async {
    final all = await local.readAll();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<Booking?> getActiveHold({required int tripId}) async {
    final all = await getMyBookings(); // الأحدث أولًا
    for (final b in all) {
      if (b.tripId == tripId && b.effectiveStatus == BookingStatus.pending) {
        return b;
      }
    }
    return null;
  }

  @override
  Future<Booking?> getBooking(int bookingId) async {
    final all = await local.readAll();
    for (final b in all) {
      if (b.id == bookingId) return b;
    }
    return null;
  }

  @override
  Future<void> saveBooking(Booking booking) async {
    final all = await local.readAll();
    all.removeWhere((b) => b.id == booking.id);
    all.add(BookingModel.fromEntity(booking));
    await local.writeAll(all);
  }

  @override
  Future<PaymentSession> startPayment(int bookingId) async {
    final session = await remote.startPayment(bookingId);
    // نحفظ رابط الجلسة لإعادة عرض التذكرة لاحقًا
    await _update(bookingId, (b) => b.copyWith(paymentUrl: session.checkoutUrl));
    return session;
  }

  @override
  Future<void> markPaid(int bookingId) =>
      _update(bookingId, (b) => b.copyWith(status: BookingStatus.confirmed));

  @override
  Future<void> cancelBooking(int bookingId) async {
    await remote.cancelBooking(bookingId); // إن فشل لا نغيّر الحالة محليًا
    await _update(
      bookingId,
      (b) => b.copyWith(status: BookingStatus.cancelled),
    );
  }

  Future<void> _update(int bookingId, Booking Function(Booking) change) async {
    final all = await local.readAll();
    final updated = all
        .map((b) => b.id == bookingId ? BookingModel.fromEntity(change(b)) : b)
        .toList();
    await local.writeAll(updated);
  }
}
