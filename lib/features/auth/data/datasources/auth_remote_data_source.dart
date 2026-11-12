import 'package:wijha_app/core/network/api_client.dart';
import 'package:wijha_app/core/network/api_endpoints.dart';
import 'package:wijha_app/core/network/api_exception.dart';

class AuthRemoteDataSource {
  final ApiClient client;
  AuthRemoteDataSource(this.client);

  Future<String> login(String email, String password) async {
    final json = await client.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    // سكربت Postman يقرأ data.token أو token، فندعم الاثنين
    final data = json['data'];
    final token = (data is Map ? data['token'] : null) ?? json['token'];
    if (token == null) {
      throw const UnknownException('لم يصل رمز الدخول من الخادم');
    }
    return token.toString();
  }

  Future<void> forgotPassword(String email) async {
    final json = await client.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
    );
    if (json['success'] == false) {
      throw UnknownException(json['message']?.toString());
    }
  }

  Future<void> register({
  required String name,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  final json = await client.post(
    ApiEndpoints.register,
    body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    },
  );
  if (json['success'] == false) {
    throw UnknownException(json['message']?.toString());
  }
}
}