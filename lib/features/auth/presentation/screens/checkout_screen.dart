import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/seat_repository.dart';
import '../cubit/checkout_cubit.dart';

enum _LeaveChoice { cancelBooking, leave, stay }

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
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: _onState,
        builder: (context, state) {
          return PopScope(
            // ما دام الحجز المؤقت قائمًا نسأل المستخدم قبل الخروج
            canPop: !(state.canCancel || state.isBusy),
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _askBeforeLeaving(context);
            },
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
              body: SingleChildScrollView(
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
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────── ردود الفعل على تغيّر الحالة ─────────────
  void _onState(BuildContext context, CheckoutState state) {
    final messenger = ScaffoldMessenger.of(context);
    switch (state.status) {
      case CheckoutStatus.failure:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'حدث خطأ غير متوقع'),
              backgroundColor: AppColors.error,
            ),
          );
      case CheckoutStatus.cancelled:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('تم إلغاء الحجز وتحرير المقاعد')),
          );
        // نعود لشاشة المقاعد (true = حدّثي الخريطة)
        Navigator.pop(context, true);
      default:
        break;
    }
  }

  // ───────────── الإلغاء ─────────────
  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الحجز؟'),
        content: Text(
          'سيتم تحرير المقاعد (${seatNumbers.join('، ')}) ولن تتمكن من استعادتها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'نعم، ألغِ الحجز',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (yes == true) cubit.cancel();
  }

  // عند الضغط على رجوع والحجز المؤقت قائم
  Future<void> _askBeforeLeaving(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    if (cubit.state.isBusy) return;

    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لديك حجز مؤقت'),
        content: const Text(
          'المقاعد محجوزة لك حتى انتهاء المهلة. هل تريد إلغاء الحجز الآن؟',
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveChoice.stay),
            child: const Text('البقاء هنا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveChoice.leave),
            child: const Text('الخروج مع الاحتفاظ بالحجز'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _LeaveChoice.cancelBooking),
            child: const Text(
              'إلغاء الحجز',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    switch (choice) {
      case _LeaveChoice.cancelBooking:
        cubit.cancel();
      case _LeaveChoice.leave:
        Navigator.pop(context, true);
      case _LeaveChoice.stay:
      case null:
        break;
    }
  }

  // ───────────── بطاقة تفاصيل الحجز ─────────────
  Widget _bookingCard(CheckoutState state) {
    final isPaid = state.status == CheckoutStatus.success;
    final isDead =
        state.status == CheckoutStatus.expired ||
        state.status == CheckoutStatus.conflict ||
        state.status == CheckoutStatus.cancelled;
    final isCancelling = state.status == CheckoutStatus.cancelling;

    final (String label, Color color) = isPaid
        ? ('مؤكد', AppColors.successGreen)
        : isDead
        ? ('غير صالح', AppColors.errorRed)
        : isCancelling
        ? ('جارٍ الإلغاء', AppColors.errorRed)
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
          // TODO: المسار والتوقيت (من وإلى، ووقت المغادرة) من تفاصيل الرحلة
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

  // ───────────── الأزرار والبطاقات السفلية ─────────────
  Widget _payButton(BuildContext context, CheckoutState state) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // يتعطل عند انتهاء المهلة أو التعارض أو أثناء الإرسال والإلغاء
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
            : Text(
                'تأكيد الحجز والدفع الآن',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: state.canPay ? Colors.white : Colors.grey.shade600,
                ),
              ),
      ),
    );
  }

  Widget _cancelButton(BuildContext context, CheckoutState state) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorRed,
          side: BorderSide(
            color: state.canCancel
                ? AppColors.errorRed
                : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: state.canCancel ? () => _confirmCancel(context) : null,
        child: state.status == CheckoutStatus.cancelling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.errorRed,
                ),
              )
            : const Text(
                'إلغاء الحجز',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
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
          _payButton(context, state), // معطّل
          const SizedBox(height: 16),
          _NoticeCard(
            color: AppColors.errorRed,
            icon: Icons.timer_off_outlined,
            title: 'انتهت مهلة الحجز',
            message: 'تم تحرير المقاعد. اختر مقاعد من جديد.',
            buttonLabel: 'اختيار مقاعد من جديد',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case CheckoutStatus.conflict:
        return [
          _payButton(context, state), // معطّل
          const SizedBox(height: 16),
          _NoticeCard(
            color: AppColors.errorRed,
            icon: Icons.error_outline,
            title: 'تعذّر تأكيد الحجز',
            message: state.message ?? 'تعارض في الحجز',
            buttonLabel: 'تحديث المقاعد',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case CheckoutStatus.cancelled:
        return const []; // لحظة عابرة: الشاشة تُغلق من الـ listener
      case CheckoutStatus.active:
      case CheckoutStatus.submitting:
      case CheckoutStatus.failure:
      case CheckoutStatus.cancelling:
        return [
          _payButton(context, state),
          const SizedBox(height: 12),
          _cancelButton(context, state),
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
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.4),
        ),
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
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
