import 'package:equatable/equatable.dart';

enum BookingStatus { pending, confirmed, cancelled, expired }

class Booking extends Equatable {
  final int id;
  final int tripId;
  final List<String> seatNumbers;
  final int pricePerSeat;
  final int totalPrice;
  final String currency;
  final String busNumber;
  final String? origin;
  final String? destination;
  final DateTime? departureTime;
  final DateTime expiresAt; // نهاية مهلة الحجز المؤقت
  final DateTime createdAt;
  final BookingStatus status; // الحالة المخزّنة
  final String? paymentUrl; // رابط جلسة الدفع / التذكرة

  const Booking({
    required this.id,
    required this.tripId,
    required this.seatNumbers,
    required this.pricePerSeat,
    required this.totalPrice,
    required this.currency,
    required this.busNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.expiresAt,
    required this.createdAt,
    required this.status,
    required this.paymentUrl,
  });

  bool get isHoldExpired => !expiresAt.isAfter(DateTime.now());

  // الحالة الفعلية: حجز معلّق انتهت مهلته يُعتبر منتهيًا
  BookingStatus get effectiveStatus =>
      (status == BookingStatus.pending && isHoldExpired)
      ? BookingStatus.expired
      : status;

  Booking copyWith({
    BookingStatus? status,
    String? paymentUrl,
    DateTime? expiresAt,
  }) {
    return Booking(
      id: id,
      tripId: tripId,
      seatNumbers: seatNumbers,
      pricePerSeat: pricePerSeat,
      totalPrice: totalPrice,
      currency: currency,
      busNumber: busNumber,
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt,
      status: status ?? this.status,
      paymentUrl: paymentUrl ?? this.paymentUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    seatNumbers,
    pricePerSeat,
    totalPrice,
    currency,
    busNumber,
    origin,
    destination,
    departureTime,
    expiresAt,
    createdAt,
    status,
    paymentUrl,
  ];
}
