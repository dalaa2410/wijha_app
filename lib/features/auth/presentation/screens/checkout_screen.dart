import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/seat_repository.dart';
import '../cubit/checkout_cubit.dart';

class CheckoutScreen extends StatelessWidget {
  final Reservation reservation;
  final List<String> seatNumbers;
  final int pricePerSeat;
  final int totalPrice;
  final String currency;
  final String busNumber;

  const CheckoutScreen({
    super.key,
    required this.reservation,
    required this.seatNumbers,
    required this.pricePerSeat,
    required this.totalPrice,
    required this.currency,
    required this.busNumber,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutCubit(
        repository: sl<SeatRepository>(),
        bookingId: reservation.bookingId,
        expiresAt: reservation.expiresAt,
      )..start(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.primaryNavy,
          centerTitle: true,
          title: const Text(
            'مراجعة الحجز',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state.status == CheckoutStatus.failure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message ?? 'حدث خطأ غير متوقع'),
                    backgroundColor: AppColors.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _CountdownCard(state: state),
                  const SizedBox(height: 16),
                  _bookingCard(state),
                  const SizedBox(height: 24),
                  ..._bottomSection(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bookingCard(CheckoutState state) {
    final isPaid = state.status == CheckoutStatus.success;
    final isDead = state.status == CheckoutStatus.expired ||
        state.status == CheckoutStatus.conflict;

    final (String label, Color color) = isPaid
        ? ('مؤكد', AppColors.successGreen)
        : isDead
            ? ('غير صالح', AppColors.errorRed)
            : ('بانتظار الدفع', AppColors.warningOrange);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحجز #${reservation.bookingId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryNavy,
                ),
              ),
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
            ],
          ),
          const Divider(height: 28),
          // TODO: المسار والتوقيت (دمشق ← حلب، 08:00) يحتاجان endpoint لتفاصيل الرحلة من الباك
          _row('الحافلة', busNumber),
          _row('المقاعد', seatNumbers.join('، ')),
          _row(
            'الرسوم',
            '${seatNumbers.length} × ${formatPrice(pricePerSeat, currency)}',
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المجموع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                formatPrice(totalPrice, currency),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bottomSection(BuildContext context, CheckoutState state) {
    switch (state.status) {
      case CheckoutStatus.success:
        return [
          _NoticeCard(
            color: AppColors.successGreen,
            icon: Icons.check_circle_outline,
            title: 'تم تأكيد حجزك',
            message: 'رقم الحجز: #${reservation.bookingId}',
            buttonLabel: 'العودة',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case CheckoutStatus.expired:
        return [
          _NoticeCard(
            color: AppColors.errorRed,
            icon: Icons.timer_off_outlined,
            title: 'انتهت مهلة الحجز',
            message: 'تم تحرير المقاعد. اختاري مقاعد من جديد.',
            buttonLabel: 'اختيار مقاعد من جديد',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case CheckoutStatus.conflict:
        return [
          _NoticeCard(
            color: AppColors.errorRed,
            icon: Icons.error_outline,
            title: 'تعذّر تأكيد الحجز',
            message: state.message ?? 'تعارض في الحجز',
            buttonLabel: 'تحديث المقاعد',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case CheckoutStatus.active:
      case CheckoutStatus.submitting:
      case CheckoutStatus.failure:
        return [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor:
                    AppColors.primaryBlue.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: state.canPay
                  ? () => context.read<CheckoutCubit>().confirm()
                  : null,
              child: state.status == CheckoutStatus.submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'تأكيد الحجز والدفع الآن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ];
    }
  }
}

class _CountdownCard extends StatelessWidget {
  final CheckoutState state;
  const _CountdownCard({required this.state});

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final expired = state.status == CheckoutStatus.expired;
    final paid = state.status == CheckoutStatus.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid ? 'تم الدفع' : 'أكمل الدفع خلال:',
                  style: const TextStyle(
                    color: AppColors.warningOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'حجز مؤقت · تعود المقاعد متاحة عند انتهاء الوقت.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            paid ? '--:--' : _format(state.secondsRemaining),
            style: TextStyle(
              color: expired ? AppColors.errorRed : AppColors.warningOrange,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _NoticeCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}