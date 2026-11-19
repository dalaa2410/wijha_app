import 'package:equatable/equatable.dart';
import 'booking.dart';
import 'payment_session.dart';

// ما تعرضه شاشة "تم الدفع بنجاح": الحجز + جلسة الدفع + وقت الدفع
class PaymentReceipt extends Equatable {
  final Booking booking;
  final PaymentSession session;
  final DateTime paidAt;

  const PaymentReceipt({
    required this.booking,
    required this.session,
    required this.paidAt,
  });

  // المبلغ المدفوع: من جلسة البوابة إن وُجد، وإلا من الحجز
  int get amount => session.amount > 0 ? session.amount : booking.totalPrice;
  String get currency =>
      session.amount > 0 ? session.currency : booking.currency;

  @override
  List<Object?> get props => [booking, session, paidAt];
}
