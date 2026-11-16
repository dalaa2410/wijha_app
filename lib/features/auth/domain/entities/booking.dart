import 'package:equatable/equatable.dart';

class BookingTrip extends Equatable {
  final int id;
  final String origin;
  final String destination;
  final DateTime? departureTime;
  final String busNumber;

  const BookingTrip({
    required this.id,
    required this.origin,
    required this.destination,
    this.departureTime,
    required this.busNumber,
  });

  @override
  List<Object?> get props => [id, origin, destination, departureTime, busNumber];
}

class BookingSeat extends Equatable {
  final int id;
  final String seatNumber;
  final int row;
  final int column;

  const BookingSeat({
    required this.id,
    required this.seatNumber,
    required this.row,
    required this.column,
  });

  @override
  List<Object?> get props => [id, seatNumber, row, column];
}

class Booking extends Equatable {
  final int id;
  final String status;
  final num totalPrice;
  final DateTime? expiresAt;
  final BookingTrip trip;
  final List<BookingSeat> seats;

  const Booking({
    required this.id,
    required this.status,
    required this.totalPrice,
    this.expiresAt,
    required this.trip,
    required this.seats,
  });

  @override
  List<Object?> get props => [id, status, totalPrice, expiresAt, trip, seats];
}