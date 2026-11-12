import '../../domain/entities/seat.dart';

class SeatModel extends Seat {
  const SeatModel({
    required super.id,
    required super.number,
    required super.row,
    required super.column,
    required super.type,
    required super.status,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    final isAvailable = json['is_available'] as bool? ?? false;
    return SeatModel(
      id: json['id'] as int,
      number: json['seat_number'] as String?,
      row: json['row'] as int,
      column: json['column'] as int,
      type: _parseType(json['type'] as String?),
      status: isAvailable ? SeatStatus.available : SeatStatus.booked,
    );
  }

  // أي نوع جديد يضيفه الباك لاحقًا يصبح unknown بدل أن ينهار التطبيق
  static SeatType _parseType(String? raw) => switch (raw) {
        'seat' => SeatType.seat,
        'aisle' => SeatType.aisle,
        'door' => SeatType.door,
        _ => SeatType.unknown,
      };
}