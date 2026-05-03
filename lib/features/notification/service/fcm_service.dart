import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/storage/token_storage.dart';
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
      debugPrint('[FCM] showLocalNotification: notification payload is null, skip');
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

  final id = DateTime.now().millisecondsSinceEpoch % 100000;
  try {
    await _localNotifications.show(id, notification.title, notification.body, details);
    if (kDebugMode) {
      debugPrint('[FCM] local notification shown: id=$id title=${notification.title}');
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
    // SchoolPage가 다시 생성되더라도 FCM 리스너가 중복 등록되지 않도록 한 번만 초기화한다.
    if (_initialized) return;
    _initialized = true;

    if (kDebugMode) debugPrint('[FCM] init() called, platform: $defaultTargetPlatform');
    if (!_isMobile) {
      if (kDebugMode) debugPrint('[FCM] 모바일 아님 — 종료');
      return;
    }

    await _initLocalNotifications();
    await _requestPermission();
    await _registerToken();

    // 포그라운드: 알림 OFF된 채팅방이면 로컬 알림 표시 생략
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) debugPrint('[FCM] onMessage fired: ${message.notification?.title}');

      if (_isMutedChatRoom(message.data)) {
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

    // 로그인 여부 확인 후 라우팅
    final role = await TokenStorage().getUserRole();
    if (role == null) {
      router.push(AppRoutes.login);
      return;
    }

    final data = message.data;
    final targetType = data['targetType'];
    final targetIdStr = data['targetId'];

    if (_isChatMessage(data)) {
      router.push(AppRoutes.chat);
      return;
    }

    if (targetType == 'POST' && targetIdStr != null) {
      final id = int.tryParse(targetIdStr);
      if (id != null) {
        router.push('/post/$id');
        return;
      }
    }
    router.push(AppRoutes.notifications);
  }

  void _refreshUnreadCount() {
    try {
      _ref.read(notificationProvider.notifier).loadUnreadCount();
    } catch (_) {}
  }

  bool _isChatMessage(Map<String, dynamic> data) {
    return data['type'] == 'CHAT' || data['targetType'] == 'CHAT_MSG';
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
    // 채팅 푸시를 받은 시점에만 채팅방 목록을 갱신해 하단 채팅 배지를 최신화한다.
    // 주기 폴링 없이 이벤트 기반으로 동작하므로 배포 환경에서 불필요한 API 호출을 줄인다.
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
    await _localNotifications.initialize(initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );
    if (kDebugMode) debugPrint('[FCM] notification channel created: $_channelId');
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
