import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/school_model.dart';

/// SchoolApi 주입용 provider
final schoolApiProvider = Provider<SchoolApi>((ref) {
  final dio = ref.read(dioProvider);
  return SchoolApi(dio);
});

class SchoolApi {
  final Dio _dio;

  SchoolApi(this._dio);

  /// 학교 검색 API 호출
  Future<List<SchoolModel>> searchSchools(String keyword) async {
    final response = await _dio.get(
      '/api/schools/search',
      queryParameters: {
        'keyword': keyword,
      },
    );

    /// 백엔드 응답에서 실제 리스트 추출
    final list = _extractSchoolList(response.data);

    return list
        .map((e) => SchoolModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 백엔드 응답이
  /// 1) 리스트 자체일 수도 있고
  /// 2) ApiResponse 안의 result/data로 감싸져 있을 수도 있어서 둘 다 대응
  List<dynamic> _extractSchoolList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final candidates = [
        data['result'],
        data['data'],
        data['results'],
        data['content'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate;
        }
      }
    }

    return [];
  }
}