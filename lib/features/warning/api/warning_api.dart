import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/warning_model.dart';

final warningApiProvider = Provider<WarningApi>((ref) {
  return WarningApi(AppApiClient(ref.watch(dioProvider)));
});

class WarningApi {
  final AppApiClient _client;

  WarningApi(this._client);

  /// 미확인 경고 조회 — 없으면 null 반환
  Future<UnreadWarningModel?> getUnreadWarning() async {
    final res = await _client.get('/api/warnings/me/unread');
    final result = res['result'];
    if (result == null) return null;
    return UnreadWarningModel.fromJson(result as Map<String, dynamic>);
  }

  /// 경고 읽음 처리
  Future<void> markWarningRead(int warningId) async {
    await _client.post('/api/warnings/me/$warningId/read');
  }

  /// 내 경고 이력 조회 (페이징)
  Future<List<WarningHistoryModel>> getMyWarnings({
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.get(
      '/api/warnings/me',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final content = (res['result']?['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => WarningHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
