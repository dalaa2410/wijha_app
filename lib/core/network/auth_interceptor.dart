import 'package:dio/dio.dart';
import 'token_storage.dart';

// يمر عليه كل طلب قبل خروجه ويضيف الـ Token إن وُجد
class AuthInterceptor extends Interceptor {
  final TokenStorage storage;
  AuthInterceptor(this.storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}