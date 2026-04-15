class ApiResponse<T> {
  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  const ApiResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    required this.result,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic data) parser,
      ) {
    return ApiResponse<T>(
      isSuccess: json['isSuccess'] as bool? ?? false,
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      result: json.containsKey('result') ? parser(json['result']) : null,
    );
  }
}