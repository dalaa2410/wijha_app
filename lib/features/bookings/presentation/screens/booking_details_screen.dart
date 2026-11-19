import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/core/utils/date_formatter.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import 'package:wijha_app/core/utils/url_opener.dart';
import 'package:wijha_app/core/widgets/app_resume_listener.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/booking_repository.dart';
import '../cubit/booking_details_cubit.dart';
import 'payment_success_screen.dart';

enum _LeaveChoice { cancelBooking, leave, stay }

/// شاشة تفاصيل الحجز: معلّق (عدّاد + دفع عبر المتصفح + إلغاء) أو مدفوع
/// (تذكرة + إلغاء) أو منتهٍ/ملغى (عرض فقط). تعيد true عند الإغلاق ليُحدَّث ما قبلها.
class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;
  const BookingDetailsScreen({super.key, required this.booking});

  // يمنع ظهور نافذة "هل أكملت الدفع؟" مرتين
  static bool _asking = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingDetailsCubit(
        repository: sl<BookingRepository>(),
        booking: booking,
      )..start(),
      child: BlocConsumer<BookingDetailsCubit, BookingDetailsState>(
        // العدّاد يغيّر الحالة كل ثانية، فنستمع فقط للتغيرات المهمة
        listenWhen: (prev, curr) =>
            prev.flow != curr.flow ||
            prev.message != curr.message ||
            prev.session != curr.session ||
            prev.receipt != curr.receipt,
        listener: _onState,
        builder: (context, state) {
          return PopScope(
            // الحجز المعلّق القائم: نسأل قبل الخروج
            canPop: !(state.canPay || state.isBusy),
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
                  'تفاصيل الحجز',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // عند العودة من المتصفح نسأل: هل أكملت الدفع؟
              body: AppResumeListener(
                onResumed: () => _onAppResumed(context),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _StatusBanner(state: state),
                      const SizedBox(height: 16),
                      _bookingCard(state),
                      const SizedBox(height: 24),
                      ..._bottomSection(context, state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────── ردود الفعل على تغيّر الحالة ─────────────
  void _onState(BuildContext context, BookingDetailsState state) {
    final messenger = ScaffoldMessenger.of(context);

    // جلسة دفع جاهزة: نفتح صفحة الدفع في المتصفح
    if (state.session != null) {
      _openPayment(context, state.session!);
      return;
    }

    // اكتمل الدفع: نعرض شاشة النجاح
    if (state.receipt != null) {
      _showSuccess(context, state.receipt!);
      return;
    }

    if (state.flow == BookingFlow.cancelled) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تم إلغاء الحجز وتحرير المقاعد')),
        );
      Navigator.pop(context, true);
      return;
    }

    // رسالة خطأ (فشل الدفع أو الإلغاء)
    final showError =
        state.message != null &&
        (state.flow == BookingFlow.failure ||
            state.flow == BookingFlow.confirmed);
    if (showError) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message!),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  // ───────────── الدفع عبر المتصفح ─────────────
  Future<void> _openPayment(
    BuildContext context,
    PaymentSession session,
  ) async {
    await _openUrl(context, session.checkoutUrl);
  }

  Future<void> _openUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final ok = await openExternalUrl(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذّر فتح المتصفح. جرّب فتح الرابط مرة أخرى.'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  // عاد المستخدم إلى التطبيق وهو بانتظار نتيجة الدفع
  Future<void> _onAppResumed(BuildContext context) async {
    final cubit = context.read<BookingDetailsCubit>();
    if (cubit.state.flow != BookingFlow.awaitingPayment || _asking) return;

    _asking = true;
    final paid = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('هل أكملت الدفع؟'),
        content: const Text(
          'إن أكدت الدفع في صفحة المتصفح وظهرت لك التذكرة، اضغط "نعم".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('لا، لم أكمل'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('نعم، أكملت الدفع'),
          ),
        ],
      ),
    );
    _asking = false;
    if (paid == null || !context.mounted) return;
    cubit.paymentClosed(paid: paid);
  }

  Future<void> _showSuccess(
    BuildContext context,
    PaymentReceipt receipt,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaymentSuccessScreen(receipt: receipt),
      ),
    );
  }

  // ───────────── الإلغاء ─────────────
  Future<void> _confirmCancel(BuildContext context, bool paid) async {
    final cubit = context.read<BookingDetailsCubit>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الحجز؟'),
        content: Text(
          paid
              ? 'هذا الحجز مدفوع. سيتم إلغاؤه وتحرير المقاعد (${booking.seatNumbers.join('، ')}). قد تطبَّق سياسة الاسترداد.'
              : 'سيتم تحرير المقاعد (${booking.seatNumbers.join('، ')}) ولن تتمكن من استعادتها.',
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

  // عند الضغط على رجوع والحجز المعلّق قائم
  Future<void> _askBeforeLeaving(BuildContext context) async {
    final cubit = context.read<BookingDetailsCubit>();
    if (cubit.state.isBusy) return;

    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لديك حجز معلّق'),
        content: const Text(
          'المقاعد محجوزة لك حتى انتهاء المهلة. يمكنك العودة إليه من "حجوزاتي". هل تريد إلغاء الحجز الآن؟',
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
  Widget _bookingCard(BookingDetailsState state) {
    final b = state.booking;
    final hasRoute = b.origin != null && b.destination != null;
    final dep = b.departureTime;

    final (String label, Color color) = switch (state.flow) {
      BookingFlow.confirmed => ('مؤكد', AppColors.successGreen),
      BookingFlow.expired ||
      BookingFlow.conflict => ('غير صالح', AppColors.errorRed),
      BookingFlow.cancelled => ('ملغى', AppColors.errorRed),
      BookingFlow.cancelling => ('جارٍ الإلغاء', AppColors.errorRed),
      _ => ('بانتظار الدفع', AppColors.warningOrange),
    };

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
                'الحجز #${b.id}',
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
          if (hasRoute)
            _row('الرحلة', '${b.origin} ← ${b.destination}', rtl: true),
          if (dep != null) _row('المغادرة', formatDeparture(dep)),
          if (b.busNumber.isNotEmpty) _row('الحافلة', b.busNumber),
          _row('المقاعد', b.seatNumbers.join('، ')),
          _row(
            'الرسوم',
            '${b.seatNumbers.length} × ${formatPrice(b.pricePerSeat, b.currency)}',
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
                formatPrice(b.totalPrice, b.currency),
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

  Widget _row(String title, String value, {bool rtl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              value,
              textAlign: rtl ? TextAlign.right : TextAlign.end,
              textDirection: rtl ? TextDirection.rtl : null,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── الأزرار والبطاقات السفلية ─────────────
  Widget _payButton(BuildContext context, BookingDetailsState state) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // يتعطل عند انتهاء المهلة أو التعارض أو أثناء الدفع والإلغاء
        onPressed: state.canPay
            ? () => context.read<BookingDetailsCubit>().pay()
            : null,
        icon: state.flow == BookingFlow.startingPayment
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(
                Icons.open_in_browser,
                color: state.canPay ? Colors.white : Colors.grey.shade600,
              ),
        label: Text(
          'ادفع الآن عبر المتصفح',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: state.canPay ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _cancelButton(BuildContext context, BookingDetailsState state) {
    final paid = state.flow == BookingFlow.confirmed;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorRed,
          side: BorderSide(
            color: state.canCancel ? AppColors.errorRed : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: state.canCancel ? () => _confirmCancel(context, paid) : null,
        child: state.flow == BookingFlow.cancelling
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

  List<Widget> _bottomSection(BuildContext context, BookingDetailsState state) {
    switch (state.flow) {
      case BookingFlow.confirmed:
        return [
          if (state.booking.paymentUrl != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _openUrl(context, state.booking.paymentUrl),
                icon: const Icon(Icons.qr_code_2, color: Colors.white),
                label: const Text(
                  'عرض التذكرة (QR)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _cancelButton(context, state),
        ];
      case BookingFlow.awaitingPayment:
        return [
          _AwaitingPaymentCard(
            onReopen: () => _openUrl(context, state.booking.paymentUrl),
            onDone: () =>
                context.read<BookingDetailsCubit>().paymentClosed(paid: true),
            onNotDone: () =>
                context.read<BookingDetailsCubit>().paymentClosed(paid: false),
          ),
        ];
      case BookingFlow.expired:
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
      case BookingFlow.conflict:
        return [
          _payButton(context, state), // معطّل
          const SizedBox(height: 16),
          _NoticeCard(
            color: AppColors.errorRed,
            icon: Icons.error_outline,
            title: 'تعذّر إتمام الحجز',
            message: state.message ?? 'تعارض في الحجز',
            buttonLabel: 'تحديث المقاعد',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case BookingFlow.cancelled:
        return [
          _NoticeCard(
            color: AppColors.textSecondary,
            icon: Icons.cancel_outlined,
            title: 'هذا الحجز ملغى',
            message: 'تم تحرير مقاعد هذا الحجز.',
            buttonLabel: 'رجوع',
            onPressed: () => Navigator.pop(context, true),
          ),
        ];
      case BookingFlow.active:
      case BookingFlow.startingPayment:
      case BookingFlow.failure:
      case BookingFlow.cancelling:
        return [
          _payButton(context, state),
          const SizedBox(height: 12),
          _cancelButton(context, state),
        ];
    }
  }
}

// بطاقة "بانتظار إتمام الدفع في المتصفح"
class _AwaitingPaymentCard extends StatelessWidget {
  final VoidCallback onReopen;
  final VoidCallback onDone;
  final VoidCallback onNotDone;

  const _AwaitingPaymentCard({
    required this.onReopen,
    required this.onDone,
    required this.onNotDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'بانتظار إتمام الدفع في المتصفح',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'أكّد الدفع في صفحة المتصفح، ثم عد إلى التطبيق واضغط "أكملت الدفع".',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onDone,
              child: const Text(
                'أكملت الدفع',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onReopen,
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text('فتح صفحة الدفع مرة أخرى'),
          ),
          TextButton(
            onPressed: onNotDone,
            child: const Text('لم أكمل الدفع'),
          ),
        ],
      ),
    );
  }
}

// بطاقة الحالة العلوية: عدّاد للمعلّق، وشريط للمؤكد والملغى
class _StatusBanner extends StatelessWidget {
  final BookingDetailsState state;
  const _StatusBanner({required this.state});

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    switch (state.flow) {
      case BookingFlow.confirmed:
        return _simple(
          AppColors.successGreen,
          Icons.check_circle_outline,
          'حجز مؤكد',
          'تم الدفع. يمكنك عرض تذكرتك في أي وقت.',
        );
      case BookingFlow.cancelled:
        return _simple(
          AppColors.textSecondary,
          Icons.cancel_outlined,
          'حجز ملغى',
          'لا يمكن استخدام هذا الحجز.',
        );
      default:
        final expired = state.flow == BookingFlow.expired;
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أكمل الدفع خلال:',
                      style: TextStyle(
                        color: AppColors.warningOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
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
                _format(state.secondsRemaining),
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

  Widget _simple(Color color, IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
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
