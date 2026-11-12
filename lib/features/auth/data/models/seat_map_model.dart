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
  });

  factory SeatMapModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final trip = data['trip'] as Map<String, dynamic>;
    final bus = data['bus'] as Map<String, dynamic>;

    return SeatMapModel(
      tripId: trip['id'] as int,
      pricePerSeat: (trip['price_per_seat'] as num).toInt(),
      currency: trip['currency'] as String,
      busNumber: bus['bus_number'] as String,
      totalRows: bus['total_rows'] as int,
      totalColumns: bus['total_columns'] as int,
      seats: (data['seats'] as List)
          .map((e) => SeatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}