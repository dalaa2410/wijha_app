import 'package:wijha_app/core/network/api_exception.dart';
import 'package:wijha_app/core/utils/json_parsing.dart';
import '../../domain/entities/payment_session.dart';

class PaymentSessionModel extends PaymentSession {
  const PaymentSessionModel({
    required super.gateway,
    required super.sessionId,
    required super.amount,
    required super.currency,
    required super.checkoutUrl,
  });

  // { success, data: { gateway, session_id, amount, currency, checkout_url } }
  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const UnknownException('رد غير متوقع من بوابة الدفع');
    }
    final url = data['checkout_url']?.toString();
    if (url == null || url.isEmpty) {
      throw const UnknownException('لم يصل رابط الدفع من الخادم');
    }
    return PaymentSessionModel(
      gateway: data['gateway']?.toString() ?? '',
      sessionId: data['session_id']?.toString() ?? '',
      amount: asInt(data['amount']) ?? 0,
      currency: data['currency']?.toString() ?? 'SYP',
      checkoutUrl: _secure(url),
    );
  }

  // الباك يرسل http لنطاق ngrok، وأندرويد يمنع http غير المشفّر،
  // فنحوّله إلى https (ngrok يدعم الاثنين)
  static String _secure(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'http' && uri.host.contains('ngrok')) {
      return uri.replace(scheme: 'https').toString();
    }
    return url;
  }
}
