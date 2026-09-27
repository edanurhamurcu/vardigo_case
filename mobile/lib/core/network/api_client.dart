import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Thin wrapper around Dio that understands the backend envelope:
///   success → { "ok": true,  "data": ... }
///   error   → { "ok": false, "error": { "code", "message" } }
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Object?> get(String path, {Map<String, Object?>? query, String? token}) {
    return _send(
      () => _dio.get<Object?>(path, queryParameters: query, options: _options(token)),
    );
  }

  Future<Object?> post(String path, {Object? body, String? token}) {
    return _send(() => _dio.post<Object?>(path, data: body, options: _options(token)));
  }

  Options _options(String? token) {
    return Options(headers: {if (token != null) 'Authorization': 'Bearer $token'});
  }

  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    final body = response.data;
    if (body case {'ok': true, 'data': final Object? data}) {
      return data;
    }
    if (body case {'ok': false, 'error': {'code': final String code, 'message': final String message}}) {
      throw ApiException(code: code, message: message, statusCode: response.statusCode);
    }
    throw ApiException.badResponse;
  }
}
