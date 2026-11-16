import 'package:equatable/equatable.dart';

class Trip extends Equatable {
  final int id;
  final String origin;
  final String destination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int pricePerSeat;
  final String currency;
  final String? busNumber;
  final String? busType;
  final int? availableSeats;
  final int? totalSeats;
  final String? status;

  const Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.pricePerSeat,
    required this.currency,
    required this.busNumber,
    required this.busType,
    required this.availableSeats,
    required this.totalSeats,
    required this.status,
  });

  // مدة الرحلة (إن توفر وقتا الانطلاق والوصول)
  Duration? get duration {
    final dep = departureTime;
    final arr = arrivalTime;
    if (dep == null || arr == null) return null;
    final diff = arr.difference(dep);
    return diff.isNegative ? null : diff;
  }

  bool get isFull => availableSeats != null && availableSeats! <= 0;

  @override
  List<Object?> get props => [
    id,
    origin,
    destination,
    departureTime,
    arrivalTime,
    pricePerSeat,
    currency,
    busNumber,
    busType,
    availableSeats,
    totalSeats,
    status,
  ];
}
