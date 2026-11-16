import '../../domain/entities/seat_map.dart';
import 'seat_model.dart';

class SeatMapModel extends SeatMap {
  SeatMapModel({
    required super.tripId,
    required super.pricePerSeat,
    required super.currency,
    required super.busNumber,
    required super.totalRows,
    required super.totalColumns,
    required super.seats,
    super.origin,
    super.destination,
    super.departureTime,
  });

  factory SeatMapModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final bus = data['bus'] as Map<String, dynamic>;

    // الشكل الجديد: حقول الرحلة مباشرة داخل data
    // الشكل القديم: داخل data.trip. ندعم الاثنين
    final trip = data['trip'] is Map<String, dynamic>
        ? data['trip'] as Map<String, dynamic>
        : data;

    return SeatMapModel(
      tripId: ((trip['trip_id'] ?? trip['id']) as num).toInt(),
      pricePerSeat: (trip['price_per_seat'] as num).toInt(),
      // الباك لم يعد يرسل العملة: نفترض الليرة السورية حتى يؤكد غير ذلك
      currency: trip['currency']?.toString() ?? 'SYP',
      busNumber: bus['bus_number'].toString(),
      totalRows: (bus['total_rows'] as num).toInt(),
      totalColumns: (bus['total_columns'] as num).toInt(),
      seats: (data['seats'] as List)
          .map((e) => SeatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      origin: trip['origin']?.toString(),
      destination: trip['destination']?.toString(),
      departureTime: DateTime.tryParse(
        trip['departure_time']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}