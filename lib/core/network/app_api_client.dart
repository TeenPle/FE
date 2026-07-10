import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'api_exception.dart';

class AppApiClient {
  final Dio _dio;

  AppApiClient(this._dio);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) =>
      _execute(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) => _execute(
    () =>
        _dio.post<dynamic>(path, data: body, queryParameters: queryParameters),
  );

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) => _execute(
    () =>
        _dio.patch<dynamic>(path, data: body, queryParameters: queryParameters),
  );

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Object jsonBody,
    List<MultipartFile> files = const [],
  }) {
    final formData = _multipartFormData(jsonBody: jsonBody, files: files);
    return _execute(() => _dio.post<dynamic>(path, data: formData));
  }

  Future<Map<String, dynamic>> patchMultipart(
    String path, {
    required Object jsonBody,
    List<MultipartFile> files = const [],
  }) {
    final formData = _multipartFormData(jsonBody: jsonBody, files: files);
    return _execute(() => _dio.patch<dynamic>(path, data: formData));
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) => _execute(
    () => _dio.delete<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
    ),
  );

  Future<Map<String, dynamic>> patchMultipartFile(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
  }) {
    final formData = FormData();
    formData.files.add(MapEntry(fieldName, file));
    return _execute(() => _dio.patch<dynamic>(path, data: formData));
  }

  Future<Map<String, dynamic>> postMultipartFile(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(fieldName, file));
    return _execute(() => _dio.post<dynamic>(path, data: formData));
  }

  FormData _multipartFormData({
    required Object jsonBody,
    required List<MultipartFile> files,
  }) {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'data',
        MultipartFile.fromString(
          jsonEncode(jsonBody),
          contentType: MediaType('application', 'json'),
        ),
      ),
    );
    for (final file in files) {
      formData.files.add(MapEntry('files', file));
    }
    return formData;
  }

  Future<Map<String, dynamic>> _execute(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      return _decodeResponse(response);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e.response?.data);
      if (message != null) {
        throw ApiException(message, statusCode: statusCode);
      }
      if (statusCode != null) {
        throw ApiException(
          '요청 처리에 실패했어요. (HTTP $statusCode)',
          statusCode: statusCode,
        );
      }
      throw ApiException('네트워크 연결을 확인해 주세요.');
    } on FormatException {
      throw ApiException('응답 형식이 올바르지 않아요.');
    }
  }

  Map<String, dynamic> _decodeResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw ApiException('응답 형식이 올바르지 않아요.', statusCode: response.statusCode);
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        return _extractErrorMessage(jsonDecode(trimmed));
      } catch (_) {
        return trimmed.length <= 120 ? trimmed : null;
      }
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in ['message', 'errorMessage', 'error', 'reason']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      final result = map['result'];
      if (result is Map) {
        final resultMessage = _extractErrorMessage(result);
        if (resultMessage != null) return resultMessage;
        final entries = result.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
        return entries.isNotEmpty ? entries : null;
      }
      if (result is String && result.trim().isNotEmpty) {
        return result.trim();
      }
      final dataValue = map['data'];
      if (dataValue is Map) {
        return _extractErrorMessage(dataValue);
      }
    }
    return null;
  }
}
