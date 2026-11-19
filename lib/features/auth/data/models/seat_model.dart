import '../../domain/entities/seat.dart';

class SeatModel extends Seat {
  const SeatModel({
    required super.id,
    required super.number,
    required super.row,
    required super.column,
    required super.type,
    required super.status,
    super.isMine,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    final row = (json['row'] as num).toInt();
    final column = (json['column'] as num).toInt();
    final isAvailable = json['is_available'] as bool? ?? false;
    final rawStatus = json['status'] as String?;

    final isMine = (json['is_mine'] as bool?) ??
        (json['is_reserved_by_me'] as bool?) ??
        (json['reserved_by_me'] as bool?) ??
        (rawStatus == 'mine' || rawStatus == 'my_seat');

    return SeatModel(
      // الممر والباب يأتيان الآن بـ id = null، فنعطيهما رقمًا سالبًا فريدًا
      id: (json['id'] as num?)?.toInt() ?? -(row * 100 + column),
      number: json['seat_number']?.toString(),
      row: row,
      column: column,
      type: _parseType(json['type'] as String?),
      status: _parseStatus(rawStatus, isAvailable),
      isMine: isMine,
    );
  }

  // أي نوع جديد يضيفه الباك لاحقًا يصبح unknown بدل أن ينهار التطبيق
  static SeatType _parseType(String? raw) => switch (raw) {
    'seat' => SeatType.seat,
    'aisle' => SeatType.aisle,
    'door' => SeatType.door,
    _ => SeatType.unknown,
  };

  // إن أرسل الباك status نستخدمه، وإلا نعتمد is_available
  static SeatStatus _parseStatus(String? raw, bool isAvailable) => switch (raw) {
    'available' => SeatStatus.available,
    'held' => SeatStatus.held,
    'booked' || 'mine' || 'my_seat' => SeatStatus.booked,
    _ => isAvailable ? SeatStatus.available : SeatStatus.booked,
  };
}