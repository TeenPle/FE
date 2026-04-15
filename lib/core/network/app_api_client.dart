import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'token_provider.dart';

class AppApiClient {
  final String baseUrl;
  final TokenProvider tokenProvider;
  final http.Client _client;

  AppApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
      String path, {
        Map<String, String>? queryParameters,
      }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String path, {
        Object? body,
        Map<String, String>? queryParameters,
      }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patch(
      String path, {
        Object? body,
        Map<String, String>? queryParameters,
      }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final response = await _client.patch(
      uri,
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
      String path, {
        Object? body,
        Map<String, String>? queryParameters,
      }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final request = http.Request('DELETE', uri);
    request.headers.addAll(await _headers());
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    return _decodeResponse(response);
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider.getAccessToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final statusCode = response.statusCode;
    final rawBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(rawBody);

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        '올바르지 않은 응답 형식입니다.',
        statusCode: statusCode,
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        decoded['message'] as String? ?? '요청 처리에 실패했습니다.',
        statusCode: statusCode,
      );
    }

    return decoded;
  }
}