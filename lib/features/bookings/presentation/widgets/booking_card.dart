import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/utils/date_formatter.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import '../../domain/entities/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onExpired;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onExpired,
  });

  (String, Color) _statusInfo(BookingStatus s) => switch (s) {
    BookingStatus.pending => ('بانتظار الدفع', AppColors.warningOrange),
    BookingStatus.confirmed => ('مؤكد', AppColors.successGreen),
    BookingStatus.cancelled => ('ملغى', AppColors.errorRed),
    BookingStatus.expired => ('منتهي', AppColors.textLight),
  };

  @override
  Widget build(BuildContext context) {
    final status = booking.effectiveStatus;
    final (label, color) = _statusInfo(status);
    final hasRoute = booking.origin != null && booking.destination != null;
    final dep = booking.departureTime;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  hasRoute
                      ? '${booking.origin} ← ${booking.destination}'
                      : 'الحجز #${booking.id}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatPrice(booking.totalPrice, booking.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Flexible(
                  child: Text(
                    'المقاعد: ${booking.seatNumbers.join('، ')}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الحجز #${booking.id}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                Flexible(
                  child: Text(
                    [
                      if (dep != null) formatDeparture(dep),
                      if (booking.busNumber.isNotEmpty)
                        'حافلة ${booking.busNumber}',
                    ].join(' · '),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (status == BookingStatus.pending) ...[
              const SizedBox(height: 12),
              _PendingStrip(booking: booking, onExpired: onExpired),
            ],
          ],
        ),
      ),
    );
  }
}

// شريط الحجز المعلّق: عدّاد وزر "إكمال الدفع"
class _PendingStrip extends StatefulWidget {
  final Booking booking;
  final VoidCallback onExpired;
  const _PendingStrip({required this.booking, required this.onExpired});

  @override
  State<_PendingStrip> createState() => _PendingStripState();
}

class _PendingStripState extends State<_PendingStrip> {
  Timer? _timer;
  late int _remaining;

  int _calc() {
    final d = widget.booking.expiresAt.difference(DateTime.now()).inSeconds;
    return d < 0 ? 0 : d;
  }

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = _calc();
      if (!mounted) return;
      setState(() => _remaining = r);
      if (r == 0) {
        _timer?.cancel();
        widget.onExpired();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$m:$s',
            style: const TextStyle(
              color: AppColors.warningOrange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Text(
            'أكمل الدفع قبل انتهاء المهلة',
            style: TextStyle(color: AppColors.warningOrange, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
