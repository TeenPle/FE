import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/active_page_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../chat/models/chat_room_model.dart';
import '../../chat/provider/chat_room_list_provider.dart';
import '../../chat/provider/muted_rooms_provider.dart';
import '../api/notification_api.dart';
import '../provider/notification_provider.dart';

bool get _isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(notificationApiProvider), ref);
});

// main.dart에서도 참조하므로 public으로 선언
const fcmChannelId = 'teenple_default';
const fcmChannelName = 'Teenple 알림';

// 내부 사용 별칭
const _channelId = fcmChannelId;
const _channelName = fcmChannelName;

final _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) {
    if (kDebugMode) {
      debugPrint(
        '[FCM] showLocalNotification: notification payload is null, skip',
      );
    }
    return;
  }

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  const details = NotificationDetails(android: androidDetails);

  // FCM data를 payload로 전달해 탭 시 라우팅에 사용한다.
  final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

  final id = DateTime.now().millisecondsSinceEpoch % 100000;
  try {
    await _localNotifications.show(
      id,
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
    if (kDebugMode) {
      debugPrint(
        '[FCM] local notification shown: id=$id title=${notification.title}',
      );
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[FCM] showLocalNotification error: $e');
  }
}

class FcmService {
  final NotificationApi _api;
  final Ref _ref;
  bool _initialized = false;

  FcmService(this._api, this._ref);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kDebugMode)
      debugPrint('[FCM] init() called, platform: $defaultTargetPlatform');
    if (!_isMobile) {
      if (kDebugMode) debugPrint('[FCM] 모바일 아님 — 종료');
      return;
    }

    await _initLocalNotifications();
    await _requestPermission();
    await _registerToken();

    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode)
        debugPrint('[FCM] onMessage fired: ${message.notification?.title}');

      // 알림 OFF된 채팅방이면 목록만 갱신하고 종료
      if (_isMutedChatRoom(message.data)) {
        _refreshChatRoomsIfChatMessage(message);
        return;
      }

      // 해당 페이지를 이미 보고 있으면 알림 표시 생략
      if (_isUserOnRelevantPage(message.data)) {
        _refreshChatRoomsIfChatMessage(message);
        return;
      }

      await showLocalNotification(message);
      _refreshUnreadCount();
      _refreshChatRoomsIfChatMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleMessageTap(m));

    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _registerToken());
  }

  Future<void> handleInitialMessage() async {
    if (!_isMobile) return;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handleMessageTap(message);
  }

  Future<void> _handleMessageTap(RemoteMessage message) async {
    _refreshUnreadCount();
    _refreshChatRoomsIfChatMessage(message);

    final role = await TokenStorage().getUserRole();
    if (role == null) {
      router.push(AppRoutes.login);
      return;
    }

    await _navigateFromData(message.data);
  }

  /// FCM data 맵을 기반으로 적절한 페이지로 이동한다.
  /// 포그라운드 로컬 알림 탭과 백그라운드/종료 알림 탭 모두 이 함수를 사용한다.
  Future<void> _navigateFromData(Map<String, dynamic> data) async {
    if (_isChatMessage(data)) {
      final roomId = int.tryParse(data['targetId'] ?? '');
      if (roomId != null) {
        await _navigateToChatRoom(roomId);
      } else {
        router.push(AppRoutes.chat);
      }
      return;
    }

    // 채팅 외 모든 알림(댓글·대댓글·좋아요 등)은 해당 게시글로 이동한다.
    final targetIdStr = data['targetId'];
    if (targetIdStr != null) {
      final postId = int.tryParse(targetIdStr);
      if (postId != null) {
        router.push('/post/$postId');
        return;
      }
    }

    router.push(AppRoutes.notifications);
  }

  /// roomId로 채팅방을 찾아 해당 채팅방 페이지로 이동한다.
  /// 목록이 아직 로드되지 않은 경우 API를 호출해 채팅방 정보를 가져온다.
  Future<void> _navigateToChatRoom(int roomId) async {
    ChatRoomModel? room = _findRoomById(
      _ref.read(chatRoomListProvider).rooms,
      roomId,
    );

    if (room == null) {
      try {
        await _ref.read(chatRoomListProvider.notifier).load();
        room = _findRoomById(_ref.read(chatRoomListProvider).rooms, roomId);
      } catch (_) {}
    }

    if (room != null) {
      router.push(
        '/chat/rooms/${room.roomId}',
        extra: {
          'otherUserId': room.otherUserId,
          'displayName': room.displayName,
          'blocked': room.blocked,
          'blockedByMe': room.blockedByMe,
          'blockedByOther': room.blockedByOther,
        },
      );
    } else {
      // room 정보를 끝내 얻지 못하면 채팅 목록으로 이동
      router.push(AppRoutes.chat);
    }
  }

  ChatRoomModel? _findRoomById(List<ChatRoomModel> rooms, int roomId) {
    for (final room in rooms) {
      if (room.roomId == roomId) return room;
    }
    return null;
  }

  void _refreshUnreadCount() {
    try {
      _ref.read(notificationProvider.notifier).loadUnreadCount();
    } catch (_) {}
  }

  bool _isChatMessage(Map<String, dynamic> data) {
    return data['type'] == 'CHAT' || data['targetType'] == 'CHAT_MSG';
  }

  /// 사용자가 현재 알림 대상 페이지를 보고 있으면 true 반환
  bool _isUserOnRelevantPage(Map<String, dynamic> data) {
    try {
      final activePage = _ref.read(activePageProvider);
      final targetId = int.tryParse(data['targetId'] ?? '');
      if (targetId == null) return false;

      if (_isChatMessage(data)) {
        return activePage.chatRoomId == targetId;
      }

      // 댓글·대댓글·좋아요 등 게시글 관련 알림
      return activePage.postId == targetId;
    } catch (_) {
      return false;
    }
  }

  // 채팅 메시지이면서 해당 채팅방 알림이 꺼진 경우 true
  bool _isMutedChatRoom(Map<String, dynamic> data) {
    if (!_isChatMessage(data)) return false;
    final roomId = int.tryParse(data['targetId'] ?? '');
    if (roomId == null) return false;
    try {
      return _ref.read(mutedRoomsProvider).contains(roomId);
    } catch (_) {
      return false;
    }
  }

  void _refreshChatRoomsIfChatMessage(RemoteMessage message) {
    if (!_isChatMessage(message.data)) return;
    try {
      _ref.read(chatRoomListProvider.notifier).load();
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      // 포그라운드에서 로컬 알림을 탭했을 때 호출된다.
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          final role = await TokenStorage().getUserRole();
          if (role == null) {
            router.push(AppRoutes.login);
            return;
          }
          await _navigateFromData(data);
        } catch (e) {
          if (kDebugMode) debugPrint('[FCM] local notification tap error: $e');
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );
    if (kDebugMode)
      debugPrint('[FCM] notification channel created: $_channelId');
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _registerToken() async {
    try {
      if (kDebugMode) debugPrint('[FCM] 토큰 요청 중...');
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      await _api.registerPushToken(token, platform);
      if (kDebugMode) debugPrint('[FCM] 서버 토큰 등록 완료');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM ERROR] $e');
    }
  }

  Future<void> reRegisterToken() async {
    if (!_isMobile) return;
    await _registerToken();
  }

  Future<void> deleteToken() async {
    if (!_isMobile) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _api.deletePushToken(token);
    } catch (_) {}
    await FirebaseMessaging.instance.deleteToken();
  }
}
