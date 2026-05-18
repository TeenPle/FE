import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/warning_history_model.dart';

final adminWarningApiProvider = Provider<AdminWarningApi>((ref) {
  return AdminWarningApi(AppApiClient(ref.watch(dioProvider)));
});

class AdminWarningApi {
  final AppApiClient _client;

  AdminWarningApi(this._client);

  Future<List<AdminWarningHistoryModel>> getWarningsByUser(int userId) async {
    final res = await _client.get(
      '/api/admin/warnings/user',
      queryParameters: {'userId': '$userId'},
    );
    final content = (res['result']?['content'] as List<dynamic>? ?? []);
    return content
        .map(
          (e) => AdminWarningHistoryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
