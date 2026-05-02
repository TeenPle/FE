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
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _dio.patch<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Object jsonBody,
    List<MultipartFile> files = const [],
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'data',
      MultipartFile.fromString(
        jsonEncode(jsonBody),
        contentType: MediaType('application', 'json'),
      ),
    ));
    for (final file in files) {
      formData.files.add(MapEntry('files', file));
    }
    final response = await _dio.post<dynamic>(path, data: formData);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchMultipart(
    String path, {
    required Object jsonBody,
    List<MultipartFile> files = const [],
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'data',
      MultipartFile.fromString(
        jsonEncode(jsonBody),
        contentType: MediaType('application', 'json'),
      ),
    ));
    for (final file in files) {
      formData.files.add(MapEntry('files', file));
    }
    final response = await _dio.patch<dynamic>(path, data: formData);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _dio.delete<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchMultipartFile(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(fieldName, file));
    final response = await _dio.patch<dynamic>(path, data: formData);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postMultipartFile(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(fieldName, file));
    final response = await _dio.post<dynamic>(path, data: formData);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        '올바르지 않은 응답 형식입니다.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
