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
    return _execute(() => _dio.post<dynamic>(path, data: formData));
  }

  Future<Map<String, dynamic>> patchMultipart(
    String path, {
    required Object jsonBody,
    List<MultipartFile> files = const [],
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

  Future<Map<String, dynamic>> _execute(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      return _decodeResponse(response);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String?;
        if (message != null && message.isNotEmpty) {
          throw ApiException(message, statusCode: e.response?.statusCode);
        }
      }
      throw ApiException(
        '네트워크 오류가 발생했습니다.',
        statusCode: e.response?.statusCode,
      );
    }
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

  Map<String, dynamic> _decodeResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException('올바르지 않은 응답 형식입니다.', statusCode: response.statusCode);
    }
    return data;
  }
}
