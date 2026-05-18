import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/notification_api.dart';
import '../models/user_setting_model.dart';

final notificationSettingProvider =
    AsyncNotifierProvider<NotificationSettingNotifier, UserSettingModel>(
      NotificationSettingNotifier.new,
    );

class NotificationSettingNotifier extends AsyncNotifier<UserSettingModel> {
  @override
  Future<UserSettingModel> build() async {
    return ref.read(notificationApiProvider).getUserSetting();
  }

  Future<void> updateSetting(Map<String, dynamic> patch) async {
    final prev = state.valueOrNull;
    if (prev == null) return;

    // 낙관적 업데이트
    state = AsyncData(_applyPatch(prev, patch));

    try {
      final updated = await ref
          .read(notificationApiProvider)
          .updateUserSetting(patch);
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(prev);
      rethrow;
    }
  }

  UserSettingModel _applyPatch(
    UserSettingModel base,
    Map<String, dynamic> patch,
  ) {
    return base.copyWith(
      allowPush: patch['allowPush'] as bool? ?? base.allowPush,
      allowCommentNotification:
          patch['allowCommentNotification'] as bool? ??
          base.allowCommentNotification,
      allowReplyNotification:
          patch['allowReplyNotification'] as bool? ??
          base.allowReplyNotification,
      allowLikeNotification:
          patch['allowLikeNotification'] as bool? ?? base.allowLikeNotification,
      allowChatNotification:
          patch['allowChatNotification'] as bool? ?? base.allowChatNotification,
    );
  }
}
