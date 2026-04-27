import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/penalty_summary_model.dart';

final adminPenaltyApiProvider = Provider<AdminPenaltyApi>((ref) {
  return AdminPenaltyApi(AppApiClient(ref.watch(dioProvider)));
});

class AdminPenaltyApi {
  final AppApiClient _client;

  AdminPenaltyApi(this._client);

  Future<List<PenaltySummaryModel>> getAllPenalties({
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.get(
      '/api/admin/penalties',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final content = (res['result']?['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => PenaltySummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
