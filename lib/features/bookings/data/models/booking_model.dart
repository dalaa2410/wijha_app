import '../../domain/entities/booking.dart';

// يحوّل الحجز إلى JSON للتخزين المحلي وبالعكس
class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.tripId,
    required super.seatNumbers,
    required super.pricePerSeat,
    required super.totalPrice,
    required super.currency,
    required super.busNumber,
    required super.origin,
    required super.destination,
    required super.departureTime,
    required super.expiresAt,
    required super.createdAt,
    required super.status,
    required super.paymentUrl,
  });

  factory BookingModel.fromEntity(Booking b) => BookingModel(
    id: b.id,
    tripId: b.tripId,
    seatNumbers: b.seatNumbers,
    pricePerSeat: b.pricePerSeat,
    totalPrice: b.totalPrice,
    currency: b.currency,
    busNumber: b.busNumber,
    origin: b.origin,
    destination: b.destination,
    departureTime: b.departureTime,
    expiresAt: b.expiresAt,
    createdAt: b.createdAt,
    status: b.status,
    paymentUrl: b.paymentUrl,
  );

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num).toInt(),
      tripId: (json['trip_id'] as num).toInt(),
      seatNumbers: (json['seat_numbers'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      pricePerSeat: (json['price_per_seat'] as num).toInt(),
      totalPrice: (json['total_price'] as num).toInt(),
      currency: json['currency']?.toString() ?? 'SYP',
      busNumber: json['bus_number']?.toString() ?? '',
      origin: json['origin']?.toString(),
      destination: json['destination']?.toString(),
      departureTime: DateTime.tryParse(
        json['departure_time']?.toString() ?? '',
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentUrl: json['payment_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trip_id': tripId,
    'seat_numbers': seatNumbers,
    'price_per_seat': pricePerSeat,
    'total_price': totalPrice,
    'currency': currency,
    'bus_number': busNumber,
    'origin': origin,
    'destination': destination,
    'departure_time': departureTime?.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'payment_url': paymentUrl,
  };
}
