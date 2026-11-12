import 'package:flutter/material.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_map.dart';
import 'seat_tile.dart';

class BusSeatGrid extends StatelessWidget {
  final SeatMap seatMap;
  final Set<int> selectedIds;
  final ValueChanged<Seat> onSeatTap;

  const BusSeatGrid({
    super.key,
    required this.seatMap,
    required this.selectedIds,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    // نثبّت الاتجاه LTR هنا ليكون العمود 1 دائمًا من اليسار كما يرسله الباك،
    // وإن أردتِ العكس غيّريه إلى TextDirection.rtl
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          // الصفوف والأعمدة تأتي من الباك، وليس من أرقام مكتوبة في الكود
          for (var r = 1; r <= seatMap.totalRows; r++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  for (var c = 1; c <= seatMap.totalColumns; c++)
                    Expanded(child: _buildCell(seatMap.seatAt(r, c))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(Seat? seat) {
    if (seat == null) return const SizedBox(height: 44);

    switch (seat.type) {
      case SeatType.seat:
        return SeatTile(
          seat: seat,
          isSelected: selectedIds.contains(seat.id),
          onTap: () => onSeatTap(seat),
        );
      case SeatType.door:
        return const SizedBox(
          height: 44,
          child: Icon(Icons.sensor_door_outlined, color: Color(0xFF94A3B8)),
        );
      case SeatType.aisle:
      case SeatType.unknown:
        return const SizedBox(height: 44);
    }
  }
}