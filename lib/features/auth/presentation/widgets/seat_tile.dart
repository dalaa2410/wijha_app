import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_ownership.dart';

class SeatTile extends StatelessWidget {
  final Seat seat;
  final bool isSelected;
  final SeatOwnership ownership;
  final VoidCallback onTap;

  const SeatTile({
    super.key,
    required this.seat,
    required this.isSelected,
    required this.onTap,
    this.ownership = SeatOwnership.none,
  });

  static const _yellow = Color(0xFFFACC15);
  static const _onYellow = Color(0xFF713F12); // نص داكن ليتضح على الأصفر

  @override
  Widget build(BuildContext context) {
    // الحالة لا تعتمد على اللون وحده: أيقونة مختلفة لكل حالة
    final (Color bg, Color fg, IconData? icon) = isSelected
        ? (AppColors.primaryBlue, Colors.white, Icons.check)
        : switch (ownership) {
            SeatOwnership.mineConfirmed => (
              AppColors.successGreen,
              Colors.white,
              Icons.verified_user_outlined,
            ),
            SeatOwnership.mineHeld => (_yellow, _onYellow, Icons.schedule),
            SeatOwnership.none => switch (seat.status) {
              SeatStatus.available => (
                const Color(0xFFE2E8F0),
                AppColors.primaryNavy,
                null,
              ),
              // محجوز أو معلّق لدى مستخدم آخر: رمادي بقفل
              SeatStatus.held || SeatStatus.booked => (
                const Color(0xFF94A3B8),
                Colors.white,
                Icons.lock_outline,
              ),
            },
          };

    final label = switch (ownership) {
      SeatOwnership.mineConfirmed => 'مقعد ${seat.number}، مدفوع',
      SeatOwnership.mineHeld => 'مقعد ${seat.number}، محجوز لك بانتظار الدفع',
      SeatOwnership.none => 'مقعد ${seat.number}',
    };

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: seat.isSelectable,
      label: label,
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
