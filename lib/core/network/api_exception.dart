sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
}

class NetworkException extends ApiException {
  const NetworkException() : super('تعذّر الاتصال بالخادم، تحقق من الإنترنت');
}

class UnauthorizedException extends ApiException {   // 401
  const UnauthorizedException([String? m]) : super(m ?? 'انتهت الجلسة، سجّلي الدخول من جديد');
}

class ConflictException extends ApiException {       // 409
  const ConflictException([String? m]) : super(m ?? 'تعارض في الحجز');
}

class ValidationException extends ApiException {     // 422
  final Map<String, List<String>> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {         // 5xx
  const ServerException([String? m]) : super(m ?? 'خطأ في الخادم، حاولي لاحقًا');
}

class UnknownException extends ApiException {
  const UnknownException([String? m]) : super(m ?? 'حدث خطأ غير متوقع');
}