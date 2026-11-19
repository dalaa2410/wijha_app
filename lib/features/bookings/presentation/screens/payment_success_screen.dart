import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/utils/date_formatter.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import 'package:wijha_app/core/utils/url_opener.dart';
import '../../domain/entities/payment_receipt.dart';

/// شاشة تظهر تلقائيًا عند اكتمال الدفع: علامة نجاح متحركة وإيصال بالتفاصيل،
/// مع زر لعرض التذكرة (QR).
class PaymentSuccessScreen extends StatelessWidget {
  final PaymentReceipt receipt;
  const PaymentSuccessScreen({super.key, required this.receipt});

  Future<void> _showTicket(BuildContext context) async {
    final url = receipt.booking.paymentUrl;
    if (url == null) return;
    final ok = await openExternalUrl(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح المتصفح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = receipt.booking;
    final hasRoute = b.origin != null && b.destination != null;
    final dep = b.departureTime;
    final gatewayLabel = receipt.session.gateway.toLowerCase() == 'sandbox'
        ? 'بوابة الدفع التجريبية'
        : receipt.session.gateway;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // الرأس المتدرج + علامة النجاح المتحركة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 70, bottom: 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryNavy, AppColors.primaryBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'تم الدفع بنجاح',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'تم تأكيد حجزك وإصدار تذكرتك',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  formatPrice(receipt.amount, receipt.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // الإيصال
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _row('رقم الحجز', '#${b.id}'),
                        if (receipt.session.sessionId.isNotEmpty)
                          _row('رقم العملية', receipt.session.sessionId),
                        if (hasRoute)
                          _row('الرحلة', '${b.origin} ← ${b.destination}', rtl: true),
                        if (dep != null) _row('المغادرة', formatDeparture(dep)),
                        if (b.busNumber.isNotEmpty) _row('الحافلة', b.busNumber),
                        _row('المقاعد', b.seatNumbers.join('، ')),
                        _row('طريقة الدفع', gatewayLabel),
                        _row(
                          'وقت الدفع',
                          '${formatDayShort(receipt.paidAt)} · ${formatTime12(receipt.paidAt)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (b.paymentUrl != null)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _showTicket(context),
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryNavy,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'تم',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value, {bool rtl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
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
}
