import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'features/notification/service/fcm_service.dart';
import 'firebase_options.dart';

// FCM은 Android/iOS에서만 동작 — Windows/macOS/Linux는 미지원
bool get _isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

// Android에서 notification 필드가 있는 FCM 메시지는 백그라운드/종료 상태일 때
// 시스템이 자동으로 알림을 표시하므로 별도 처리 불필요.
// 핸들러 등록 자체는 firebase_messaging이 백그라운드 isolate를 올바르게 초기화하기 위해 필요.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // flutter_local_notifications는 백그라운드 isolate에서 초기화되지 않으므로 호출하지 않음
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_isMobile) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // FCM 백그라운드 알림이 앱 채널 생성 전에 도달해도 헤드업이 뜨도록
    // 앱 시작 시점에 채널을 즉시 생성
    await _ensureNotificationChannel();
  }
  runApp(
    const ProviderScope(
      child: TeenpleApp(),
    ),
  );
}

Future<void> _ensureNotificationChannel() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          fcmChannelId,
          fcmChannelName,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
}
