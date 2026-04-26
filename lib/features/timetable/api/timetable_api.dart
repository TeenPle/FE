import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/timetable_model.dart';

final timetableApiProvider = Provider<TimetableApi>((ref) {
  return TimetableApi(AppApiClient(ref.watch(dioProvider)));
});

class TimetableApi {
  final AppApiClient _client;

  TimetableApi(this._client);

  Future<TimetableWeek> getTimetable({
    required String classRoom,
    required String from,
    required String to,
  }) async {
    final res = await _client.get(
      '/api/timetable/me',
      queryParameters: {'classRoom': classRoom, 'from': from, 'to': to},
    );
    return TimetableWeek.fromJson(res['result'] as Map<String, dynamic>);
  }
}
