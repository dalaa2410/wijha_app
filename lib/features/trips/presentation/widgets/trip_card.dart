import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/utils/date_formatter.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import '../../domain/entities/trip.dart';
import 'package:wijha_app/features/auth/presentation/screens/seat_map_screen.dart'; // <--- 1. استيراد شاشة المقاعد

class TripCard extends StatelessWidget {
  final Trip trip;
  final bool highlighted;
  final VoidCallback? onTap; // جعلناه اختيارياً لأنه يمكننا ربطه افتراضياً

  const TripCard({
    super.key,
    required this.trip,
    required this.highlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dep = trip.departureTime;
    final arr = trip.arrivalTime;
    final dur = trip.duration;
    final seats = trip.availableSeats;

    final title = trip.busNumber != null
        ? 'حافلة ${trip.busNumber}'
        : 'رحلة #${trip.id}';

    final subtitleParts = <String>[
      if (trip.origin.isNotEmpty && trip.destination.isNotEmpty)
        '${trip.origin} ← ${trip.destination}',
      if (trip.busType != null && trip.busType!.isNotEmpty) trip.busType!,
    ];

    // تحديد دالة الانتقال افتراضياً إذا لم يتم تمريرها من الخارج
    final VoidCallback handleTap = onTap ?? () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeatMapScreen(tripId: trip.id), // <--- تمرير الـ trip.id الفعلي لشاشة المقاعد ودفع الدفع بنجاح
        ),
      );
    };

    return InkWell(
      onTap: trip.isFull ? null : handleTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlighted ? AppColors.primaryBlue : Colors.grey.shade200,
            width: highlighted ? 1.6 : 1,
          ),
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
            // السطر الأول: السعر (يسار) وعنوان الحافلة والمسار (يمين)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPrice(trip.pricePerSeat, trip.currency),
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Text(
                        'للمقعد',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      if (subtitleParts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitleParts.join(' · '),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // سطر الأوقات: الوصول (يسار) ... المدة ... المغادرة (يمين)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TimeBlock(
                  time: arr != null ? formatTime12(arr) : null,
                  label: arr != null
                      ? 'الوصول'
                      : (dep != null ? formatDayShort(dep) : ''),
                ),
                Expanded(
                  child: dur == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Text(
                                formatDuration(dur),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_back,
                                    size: 14,
                                    color: AppColors.textLight,
                                  ),
                                  Expanded(
                                    child: Divider(
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                _TimeBlock(
                  time: dep != null ? formatTime12(dep) : '--:--',
                  label: 'المغادرة',
                ),
              ],
            ),

            // المقاعد المتاحة
            if (seats != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    trip.isFull ? 'الرحلة مكتملة' : '$seats مقعد متاح',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trip.isFull
                          ? AppColors.errorRed
                          : (seats <= 5
                              ? AppColors.warningOrange
                              : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.event_seat_outlined,
                    size: 16,
                    color: trip.isFull
                        ? AppColors.errorRed
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // زر اختيار المقاعد
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: highlighted
                      ? AppColors.primaryBlue
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  foregroundColor: highlighted
                      ? Colors.white
                      : AppColors.primaryBlue,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: trip.isFull ? null : handleTap,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'اختر المقاعد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_back, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String? time;
  final String label;
  const _TimeBlock({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          time ?? '',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}