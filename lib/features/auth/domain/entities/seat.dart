import 'package:equatable/equatable.dart';

// enum = قائمة قيم محدودة. أفضل من الـ String لأن المحرر ينبهكِ إن أخطأتِ في الاسم
enum SeatType { seat, aisle, door, unknown }

enum SeatStatus { available, held, booked }

// Equatable: يجعل مقارنة كائنين تعتمد على قيمهما وليس عنوانهما في الذاكرة،
// وهذا ما يجعل الـ Cubit يعرف أن الحالة تغيّرت فعلًا فيُعيد رسم الواجهة
class Seat extends Equatable {
  final int id;
  final String? number; // الممر والباب بلا رقم، لذلك nullable
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