import 'package:wijha_app/core/network/api_client.dart';
import 'package:wijha_app/core/network/api_endpoints.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';
import '../models/payment_session_model.dart';

abstract class BookingDataSource {
  Future<List<BookingModel>> getMyBookings();
  Future<BookingModel?> getBooking(int bookingId);
  Future<PaymentSessionModel> startPayment(int bookingId);
  Future<void> markPaid(int bookingId);
  Future<void> cancelBooking(int bookingId);
}

class BookingRemoteDataSource implements BookingDataSource {
  final ApiClient client;

  BookingRemoteDataSource(this.client);

  @override
  Future<List<BookingModel>> getMyBookings() async {
    final response = await client.get('/bookings');
    final rawList = response['results'] ?? response['data'] ?? response['bookings'];
    final list = rawList is List ? rawList : const [];
    return list
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BookingModel?> getBooking(int bookingId) async {
    final list = await getMyBookings();
    for (final b in list) {
      if (b.id == bookingId) return b;
    }
    return null;
  }

  @override
  Future<PaymentSessionModel> startPayment(int bookingId) async {
    final response = await client.post(ApiEndpoints.payBooking(bookingId));
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return PaymentSessionModel.fromJson(data);
  }

  @override
  Future<void> markPaid(int bookingId) async {
    await client.post(ApiEndpoints.confirm(bookingId));
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await client.delete(ApiEndpoints.cancelBooking(bookingId));
  }
}

class BookingMockDataSource implements BookingDataSource {
  final List<BookingModel> _mockBookings = [
    BookingModel(
      id: 101,
      tripId: 1,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 8)),
      totalPrice: 50000,
      pricePerSeat: 25000,
      currency: 'SYP',
      seatNumbers: const ['A1', 'A2'],
      origin: 'دمشق',
      destination: 'حلب',
      departureTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
      busNumber: '12',
      paymentUrl: 'mock://checkout',
    ),
  ];

  @override
  Future<List<BookingModel>> getMyBookings() async => List.of(_mockBookings);

  @override
  Future<BookingModel?> getBooking(int bookingId) async {
    try {
      return _mockBookings.firstWhere((b) => b.id == bookingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PaymentSessionModel> startPayment(int bookingId) async {
    return const PaymentSessionModel(
      gateway: 'sandbox',
      sessionId: 'mock_session_1',
      amount: 50000,
      currency: 'SYP',
      checkoutUrl: 'mock://checkout',
    );
  }

  @override
  Future<void> markPaid(int bookingId) async {
    final idx = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = _mockBookings[idx];
      _mockBookings[idx] = BookingModel(
        id: b.id,
        tripId: b.tripId,
        status: BookingStatus.confirmed,
        createdAt: b.createdAt,
        expiresAt: b.expiresAt,
        totalPrice: b.totalPrice,
        pricePerSeat: b.pricePerSeat,
        currency: b.currency,
        seatNumbers: b.seatNumbers,
        origin: b.origin,
        destination: b.destination,
        departureTime: b.departureTime,
        busNumber: b.busNumber,
        paymentUrl: b.paymentUrl,
      );
    }
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    final idx = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = _mockBookings[idx];
      _mockBookings[idx] = BookingModel(
        id: b.id,
        tripId: b.tripId,
        status: BookingStatus.cancelled,
        createdAt: b.createdAt,
        expiresAt: b.expiresAt,
        totalPrice: b.totalPrice,
        pricePerSeat: b.pricePerSeat,
        currency: b.currency,
        seatNumbers: b.seatNumbers,
        origin: b.origin,
        destination: b.destination,
        departureTime: b.departureTime,
        busNumber: b.busNumber,
        paymentUrl: b.paymentUrl,
      );
    }
  }
}