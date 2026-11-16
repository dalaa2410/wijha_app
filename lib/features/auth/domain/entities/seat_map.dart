import 'package:equatable/equatable.dart';
import 'seat.dart';

class SeatMap extends Equatable {
  final int tripId;
  final int pricePerSeat;
  final String currency;
  final String busNumber;
  final int totalRows;
  final int totalColumns;
  final List<Seat> seats;

  // تفاصيل الرحلة: اختيارية، فلا تكسر أي شاشة لا تستخدمها
  final String? origin;
  final String? destination;
  final DateTime? departureTime;

  SeatMap({
    required this.tripId,
    required this.pricePerSeat,
    required this.currency,
    required this.busNumber,
    required this.totalRows,
    required this.totalColumns,
    required this.seats,
    this.origin,
    this.destination,
    this.departureTime,
  });

  // فهرس للبحث السريع: (صف، عمود) ← المقعد
  late final Map<(int, int), Seat> _byPosition = {
    for (final seat in seats) (seat.row, seat.column): seat,
  };

  Seat? seatAt(int row, int column) => _byPosition[(row, column)];

  @override
  List<Object?> get props => [
    tripId,
    pricePerSeat,
    currency,
    busNumber,
    totalRows,
    totalColumns,
    seats,
    origin,
    destination,
    departureTime,
  ];
}