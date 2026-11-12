import 'package:equatable/equatable.dart';

class Reservation extends Equatable {
  final int bookingId;
  final DateTime? expiresAt;

  const Reservation({required this.bookingId, this.expiresAt});

  @override
  List<Object?> get props => [bookingId, expiresAt];
}