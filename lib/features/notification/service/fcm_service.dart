import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../api/notification_api.dart';
import '../provider/notification_provider.dart';

bool get _isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(notificationApiProvider), ref);
});

const _channelId = 'teenple_default';
const _channelName = 'Teenple 알림';

final _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  const details = NotificationDetails(android: androidDetails);

  await _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    details,
  );
}

class FcmService {
  final NotificationApi _api;
  final Ref _ref;

  FcmService(this._api, this._ref);

  Future<void> init() async {
    // ignore: avoid_print
    print('[FCM] init() called, platform: $defaultTargetPlatform');
    if (!_isMobile) {
      // ignore: avoid_print
      print('[FCM] 모바일 아님 — 종료');
      return;
    }

    await _initLocalNotifications();
    await _requestPermission();
    await _registerToken();

    // 포그라운드: 로컬 알림 표시 + 배지 카운트 갱신
    FirebaseMessaging.onMessage.listen((message) async {
      await showLocalNotification(message);
      _refreshUnreadCount();
    });

    // 백그라운드 상태에서 알림 탭: 해당 게시글로 이동 + 배지 갱신
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _registerToken());
  }

  /// 앱이 완전히 종료된 상태에서 알림 탭으로 실행된 경우 처리
  Future<void> handleInitialMessage() async {
    if (!_isMobile) return;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handleMessageTap(message);
  }

  void _handleMessageTap(RemoteMessage message) {
    _refreshUnreadCount();
    final data = message.data;
    final targetType = data['targetType'];
    final targetIdStr = data['targetId'];

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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // ignore: avoid_print
    print('[FCM] 권한 상태: ${settings.authorizationStatus}');
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
      // ignore: avoid_print
      print('[FCM] 토큰 요청 중...');
      final token = await FirebaseMessaging.instance.getToken();
      // ignore: avoid_print
      print('[FCM TOKEN] $token');
      if (token == null) return;

      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      await _api.registerPushToken(token, platform);
      // ignore: avoid_print
      print('[FCM] 서버 토큰 등록 완료');
    } catch (e) {
      // ignore: avoid_print
      print('[FCM ERROR] $e');
    }
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
