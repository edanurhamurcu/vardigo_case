import 'package:dio/dio.dart';

/// Single error type the UI layer deals with. Messages are user-facing (Turkish),
/// coming either from the backend envelope or from a network failure.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.statusCode});

  factory ApiException.fromDio(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ApiException(code: 'TIMEOUT', message: 'Sunucu yanıt vermedi, tekrar dene.'),
      _ => const ApiException(
          code: 'NETWORK',
          message: 'Sunucuya ulaşılamıyor. Backend çalışıyor mu?',
        ),
    };
  }

  static const badResponse = ApiException(
    code: 'BAD_RESPONSE',
    message: 'Sunucudan beklenmeyen bir yanıt geldi.',
  );

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Wraps JSON → model parsing so a malformed payload surfaces as [ApiException]
/// instead of a raw TypeError deep in the UI.
T parseResponse<T>(T Function() parse) {
  try {
    return parse();
  } on Object {
    throw ApiException.badResponse;
  }
}
