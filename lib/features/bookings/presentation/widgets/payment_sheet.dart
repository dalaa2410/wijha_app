import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import '../../domain/entities/payment_session.dart';

/// الدالة العامة التي تستدعيها BookingDetailsScreen لفتح نافذة الدفع أو عرض التذكرة
Future<bool> showPaymentSheet(
  BuildContext context,
  PaymentSession session, {
  bool ticketOnly = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PaymentSheet(
      checkoutUrl: session.checkoutUrl,
      ticketOnly: ticketOnly,
      ticketCode: session.sessionId,
    ),
  );
  return result ?? false;
}

class PaymentSheet extends StatefulWidget {
  final String checkoutUrl;
  final bool ticketOnly;
  final String? ticketCode;

  const PaymentSheet({
    super.key,
    required this.checkoutUrl,
    this.ticketOnly = false,
    this.ticketCode,
  });

  static Future<bool> show(BuildContext context, String checkoutUrl) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PaymentSheet(checkoutUrl: checkoutUrl),
    );
    return result ?? false;
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isCompleted = false;

  bool get _hasValidUrl => widget.checkoutUrl.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasValidUrl) {
      _initWebView();
    } else {
      _isLoading = false;
    }
  }

  void _initWebView() {
    final safeUrl = widget.checkoutUrl.startsWith('http://') &&
            widget.checkoutUrl.contains('ngrok')
        ? widget.checkoutUrl.replaceFirst('http://', 'https://')
        : widget.checkoutUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
            if (!widget.ticketOnly) _checkUrlForSuccess(url);
          },
          onUrlChange: (UrlChange change) {
            if (!widget.ticketOnly && change.url != null) {
              _checkUrlForSuccess(change.url!);
            }
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _isLoading = false);
            if (!widget.ticketOnly) {
              _checkUrlForSuccess(url);
              await _checkPageContentForSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(safeUrl));
  }

  void _checkUrlForSuccess(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/success') ||
        lower.contains('confirmed') ||
        lower.contains('paid') ||
        lower.contains('complete')) {
      _finishWithSuccess();
    }
  }

  Future<void> _checkPageContentForSuccess() async {
    if (_isCompleted || _controller == null) return;
    try {
      final rawText = await _controller!
          .runJavaScriptReturningResult('document.body.innerText');
      final text = rawText.toString().toLowerCase();

      if (text.contains('ticket_code') ||
          text.contains('"status":"confirmed"') ||
          text.contains('payment confirmed') ||
          text.contains('تم الدفع بنجاح')) {
        _finishWithSuccess();
      }
    } catch (_) {}
  }

  void _finishWithSuccess() {
    if (_isCompleted || !mounted) return;
    _isCompleted = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * (widget.ticketOnly ? 0.65 : 0.85),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                Row(
                  children: [
                    Icon(
                      widget.ticketOnly ? Icons.qr_code_2 : Icons.lock_outline,
                      size: 18,
                      color: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.ticketOnly ? 'تذكرة السفر الإلكترونية' : 'بوابة الدفع الآمنة',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primaryBlue,
            )
          else
            const Divider(height: 1),
          Expanded(
            child: _hasValidUrl && _controller != null
                ? WebViewWidget(controller: _controller!)
                : _buildTicketQrFallback(),
          ),
        ],
      ),
    );
  }

  /// عرض بطاقة التذكرة ورمز QR إذا لم يكن هناك رابط WebView للتذكرة
  Widget _buildTicketQrFallback() {
    final code = (widget.ticketCode != null && widget.ticketCode!.isNotEmpty)
        ? widget.ticketCode!
        : 'WIJHA-CONFIRMED';
    final qrImageUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${Uri.encodeComponent(code)}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                qrImageUrl,
                width: 200,
                height: 200,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.qr_code_2,
                  size: 180,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'أبرز هذا الرمز عند الصعود إلى الحافلة',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}