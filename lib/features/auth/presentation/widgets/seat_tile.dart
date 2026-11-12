import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import '../../domain/entities/seat.dart';

class SeatTile extends StatelessWidget {
  final Seat seat;
  final bool isSelected;
  final VoidCallback onTap;

  const SeatTile({
    super.key,
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // الحالة لا تعتمد على اللون وحده: أيقونة مختلفة لكل حالة (للمستخدمين الذين لا يميزون الألوان)
    final (Color bg, Color fg, IconData? icon) = isSelected
        ? (AppColors.primaryBlue, Colors.white, Icons.check)
        : switch (seat.status) {
            SeatStatus.available => (const Color(0xFFE2E8F0), AppColors.primaryNavy, null),
            SeatStatus.held => (const Color(0xFF94A3B8), Colors.white, Icons.schedule),
            SeatStatus.booked => (const Color(0xFF94A3B8), Colors.white, Icons.lock_outline),
          };

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: seat.isSelectable,
      label: 'مقعد ${seat.number}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: seat.isSelectable ? onTap : null,
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seat.number ?? '',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 3),
                    Icon(icon, size: 12, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}