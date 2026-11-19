import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import '../../domain/entities/booking.dart';

/// شريط في شاشة المقاعد: "لديك حجز معلّق" مع عدّاد وزر المتابعة.
/// يختفي عند انتهاء المهلة (يستدعي onExpired ليُحدَّث ما حوله).
class HoldBanner extends StatefulWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onExpired;

  const HoldBanner({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onExpired,
  });

  @override
  State<HoldBanner> createState() => _HoldBannerState();
}

class _HoldBannerState extends State<HoldBanner> {
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

  String get _time {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    _time,
                    style: const TextStyle(
                      color: AppColors.warningOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'متبقٍ',
                    style: TextStyle(
                      color: AppColors.warningOrange,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'لديك حجز معلّق لهذه الرحلة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المقاعد: ${widget.booking.seatNumbers.join('، ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'متابعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_back, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
