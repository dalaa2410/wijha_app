import 'package:equatable/equatable.dart';

// جلسة دفع يرجعها الباك (بوابة sandbox)
class PaymentSession extends Equatable {
  final String gateway;
  final String sessionId;
  final int amount;
  final String currency;
  final String checkoutUrl;

  const PaymentSession({
    required this.gateway,
    required this.sessionId,
    required this.amount,
    required this.currency,
    required this.checkoutUrl,
  });

  @override
  List<Object?> get props => [gateway, sessionId, amount, currency, checkoutUrl];
}
