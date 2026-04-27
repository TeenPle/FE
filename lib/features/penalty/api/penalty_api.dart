import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/penalty_model.dart';

final penaltyApiProvider = Provider<PenaltyApi>((ref) {
  return PenaltyApi(AppApiClient(ref.watch(dioProvider)));
});

class PenaltyApi {
  final AppApiClient _client;

  PenaltyApi(this._client);

  Future<ActivePenaltyModel> getMyActivePenalty() async {
    final res = await _client.get('/api/penalties/me');
    return ActivePenaltyModel.fromJson(res['result'] as Map<String, dynamic>);
  }

  Future<List<PenaltyHistoryModel>> getMyPenaltyHistory({
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.get(
      '/api/penalties/me/history',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final content =
        (res['result']?['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => PenaltyHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
