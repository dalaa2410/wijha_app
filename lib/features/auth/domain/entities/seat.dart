import 'package:equatable/equatable.dart';

enum SeatType { seat, aisle, door, unknown }

enum SeatStatus { available, held, booked }

class Seat extends Equatable {
  final int id;
  final String? number; // الممر والباب بلا رقم
  final int row;
  final int column;
  final SeatType type;
  final SeatStatus status;

  const Seat({
    required this.id,
    required this.number,
    required this.row,
    required this.column,
    required this.type,
    required this.status,
  });

  bool get isSeat => type == SeatType.seat;
  bool get isSelectable => isSeat && status == SeatStatus.available;

  @override
  List<Object?> get props => [id, number, row, column, type, status];
}