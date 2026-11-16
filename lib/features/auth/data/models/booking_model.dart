import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.status,
    required super.totalPrice,
    super.expiresAt,
    required super.trip,
    required super.seats,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'] as Map<String, dynamic>? ?? {};
    final seatsJson = json['seats'] as List? ?? [];

    return BookingModel(
      id: (json['id'] as num).toInt(),
      status: json['status']?.toString() ?? 'pending',
      totalPrice: (json['total_price'] as num?) ?? 0,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      trip: BookingTrip(
        id: (tripJson['id'] as num?)?.toInt() ?? 0,
        origin: tripJson['origin']?.toString() ?? '',
        destination: tripJson['destination']?.toString() ?? '',
        departureTime: DateTime.tryParse(tripJson['departure_time']?.toString() ?? ''),
        busNumber: tripJson['bus_number']?.toString() ?? '',
      ),
      seats: seatsJson
          .map((s) => BookingSeat(
                id: (s['id'] as num?)?.toInt() ?? 0,
                seatNumber: s['seat_number']?.toString() ?? '',
                row: (s['row'] as num?)?.toInt() ?? 0,
                column: (s['column'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
    );
  }
}