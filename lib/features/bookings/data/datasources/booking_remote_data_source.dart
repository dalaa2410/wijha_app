import 'package:wijha_app/core/network/api_client.dart';
import 'package:wijha_app/core/network/api_endpoints.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../models/payment_session_model.dart';

abstract class BookingRemoteDataSource {
  Future<PaymentSessionModel> startPayment(int bookingId);
  Future<void> cancelBooking(int bookingId);
}

// المصدر الحقيقي: الباك
class BookingApiDataSource implements BookingRemoteDataSource {
  final ApiClient client;
  BookingApiDataSource(this.client);

  @override
  Future<PaymentSessionModel> startPayment(int bookingId) async {
    // افتراض: POST. إن كانت الطريقة في Postman غير ذلك غيّريها هنا
    final json = await client.post(ApiEndpoints.payBooking(bookingId));
    return PaymentSessionModel.fromJson(json);
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    // افتراض: DELETE. إن كانت الطريقة في Postman غير ذلك غيّريها هنا
    final json = await client.delete(ApiEndpoints.cancelBooking(bookingId));
    if (json['success'] == false) {
      throw UnknownException(json['message']?.toString());
    }
  }
}

// مصدر تجريبي للعرض الاحتياطي: نافذة دفع محاكاة داخل التطبيق
class BookingMockDataSource implements BookingRemoteDataSource {
  @override
  Future<PaymentSessionModel> startPayment(int bookingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const PaymentSessionModel(
      gateway: 'sandbox',
      sessionId: 'MOCK-SESSION',
      amount: 0,
      currency: 'SYP',
      checkoutUrl: 'mock://sandbox',
    );
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
