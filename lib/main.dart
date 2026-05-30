import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 앱이 시스템 상태바·네비게이션 바 뒤까지 그려지도록 설정.
  // Flutter의 MediaQuery 인셋(padding.bottom 등)이 시스템 바 높이를 정확히 반영해
  // Scaffold가 콘텐츠를 자동으로 피해준다.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_isMobile) {
    // 출시 전 AdMob 연동 검증용 초기화. 실제 광고 단위 ID를 쓰기 전에도
    // Google 테스트 광고가 로드되는지 확인할 수 있다.
    await MobileAds.instance.initialize();
  }
  if (_isMobile) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    // FCM 백그라운드 알림이 앱 채널 생성 전에 도달해도 헤드업이 뜨도록
    // 앱 시작 시점에 채널을 즉시 생성
    await _ensureNotificationChannel();
  }
  runApp(const ProviderScope(child: TeenpleApp()));
}

Future<void> _ensureNotificationChannel() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
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
