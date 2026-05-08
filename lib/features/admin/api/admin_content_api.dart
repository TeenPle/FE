import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/admin_content_model.dart';

final adminContentApiProvider = Provider<AdminContentApi>((ref) {
  return AdminContentApi(AppApiClient(ref.watch(dioProvider)));
});

class AdminContentApi {
  final AppApiClient _client;

  const AdminContentApi(this._client);

  Future<List<AdminSchoolModel>> searchSchools({
    String keyword = '',
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.get(
      '/api/admin/content/schools',
      queryParameters: {
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'page': '$page',
        'size': '$size',
      },
    );
    final content = res['result']?['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => AdminSchoolModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminBoardModel>> getBoardsBySchool(int schoolId) async {
    final res = await _client.get('/api/admin/content/schools/$schoolId/boards');
    final result = res['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => AdminBoardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminPostSummaryModel>> getPostsByBoard({
    required int boardId,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.get(
      '/api/admin/content/boards/$boardId/posts',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final content = res['result']?['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => AdminPostSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPostDetailModel> getPostDetail(int postId) async {
    final res = await _client.get('/api/admin/content/posts/$postId');
    return AdminPostDetailModel.fromJson(res['result'] as Map<String, dynamic>);
  }
}
