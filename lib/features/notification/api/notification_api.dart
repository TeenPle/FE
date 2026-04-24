import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/notification_model.dart';
import '../models/user_setting_model.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(AppApiClient(ref.watch(dioProvider)));
});

class NotificationApi {
  final AppApiClient _client;

  NotificationApi(this._client);

  Future<UserSettingModel> getUserSetting() async {
    final res = await _client.get('/api/user-settings/me');
    return UserSettingModel.fromJson(res['result'] as Map<String, dynamic>);
  }

  Future<UserSettingModel> updateUserSetting(Map<String, dynamic> body) async {
    final res = await _client.patch('/api/user-settings/me', body: body);
    return UserSettingModel.fromJson(res['result'] as Map<String, dynamic>);
  }

  Future<void> registerPushToken(String token, String platform) async {
    await _client.post('/api/push-tokens', body: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> deletePushToken(String token) async {
    await _client.delete('/api/push-tokens', queryParameters: {'token': token});
  }

  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20}) async {
    final res = await _client.get('/api/notifications', queryParameters: {
      'page': '$page',
      'size': '$size',
    });
    final content = (res['result']['content'] as List<dynamic>);
    return content.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _client.get('/api/notifications/unread-count');
    return res['result']['unreadCount'] as int;
  }

  Future<void> markAsRead(int id) async {
    await _client.patch('/api/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _client.patch('/api/notifications/read-all');
  }
}
