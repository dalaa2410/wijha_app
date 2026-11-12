import 'package:dio/dio.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio _dio;
  ApiClient(this._dio);

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      throw const UnknownException('رد غير متوقع من الخادم');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      default:
        break;
    }

    final data = e.response?.data;
    final message = data is Map ? data['message']?.toString() : null;
    final status = e.response?.statusCode;

    if (status == 401) return UnauthorizedException(message);
    if (status == 409) return ConflictException(message);
    if (status == 422) {
      final errors = _parseErrors(data);
      final first = errors.values.firstOrNull?.firstOrNull;
      return ValidationException(first ?? message ?? 'بيانات غير صحيحة', errors);
    }
    if (status != null && status >= 500) return ServerException(message);
    return UnknownException(message);
  }

  // Laravel يرسل أخطاء التحقق هكذا: { "errors": { "email": ["..."] } }
  Map<String, List<String>> _parseErrors(dynamic data) {
    if (data is! Map || data['errors'] is! Map) return {};
    return (data['errors'] as Map).map(
      (k, v) => MapEntry(k.toString(), List<String>.from(v as List)),
    );
  }
}