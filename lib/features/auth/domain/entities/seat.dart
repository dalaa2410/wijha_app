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
  final bool isMine; // هل هذا المقعد محجوز/مدفوع بواسطتي؟

  const Seat({
    required this.id,
    required this.number,
    required this.row,
    required this.column,
    required this.type,
    required this.status,
    this.isMine = false,
  });

  bool get isSeat => type == SeatType.seat;
  bool get isSelectable => isSeat && status == SeatStatus.available;
  bool get isMySeat => isSeat && isMine && status != SeatStatus.available;

  @override
  List<Object?> get props => [id, number, row, column, type, status, isMine];
}