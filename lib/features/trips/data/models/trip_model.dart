import 'package:wijha_app/core/utils/json_parsing.dart';
import '../../domain/entities/trip.dart';

// ملاحظة: أسماء الحقول هنا قراءة متسامحة (نجرّب أكثر من اسم).
// عند وصول رد حقيقي فيه رحلات، عدّلي الأسماء في هذا الملف فقط.
class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.origin,
    required super.destination,
    required super.departureTime,
    required super.arrivalTime,
    required super.pricePerSeat,
    required super.currency,
    required super.busNumber,
    required super.busType,
    required super.availableSeats,
    required super.totalSeats,
    required super.status,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final busRaw = json['bus'];
    final bus = busRaw is Map<String, dynamic>
        ? busRaw
        : const <String, dynamic>{};

    final id = asInt(json['id'] ?? json['trip_id']);
    if (id == null) {
      throw const FormatException('الرحلة بلا رقم');
    }

    return TripModel(
      id: id,
      origin: (json['origin'] ?? json['from'])?.toString() ?? '',
      destination: (json['destination'] ?? json['to'])?.toString() ?? '',
      departureTime: asDate(json['departure_time'] ?? json['departure_at']),
      arrivalTime: asDate(json['arrival_time'] ?? json['arrival_at']),
      pricePerSeat:
          asInt(json['price_per_seat'] ?? json['price'] ?? json['base_price']) ??
          0,
      currency: json['currency']?.toString() ?? 'SYP',
      busNumber: (bus['bus_number'] ?? json['bus_number'])?.toString(),
      busType: (bus['type'] ?? json['bus_type'])?.toString(),
      availableSeats: asInt(json['available_seats'] ?? json['seats_available']),
      totalSeats: asInt(
        json['total_seats'] ?? bus['total_seats'] ?? bus['capacity'],
      ),
      status: json['status']?.toString(),
    );
  }
}
