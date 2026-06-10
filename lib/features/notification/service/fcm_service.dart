import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;
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
// 채널 id는 기존 설치 기기와의 호환을 위해 변경 금지. 이름은 앱 표기(TeenPle)와 통일.
const fcmChannelId = 'teenple_default';
const fcmChannelName = 'TeenPle 알림';

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
    // 브랜드 블루 — 상태바 실루엣 아이콘(ic_notification)의 틴트 색상
    color: Color(0xFF14A3F7),
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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

    if (kDebugMode) {
      debugPrint('[FCM] init() called, platform: $defaultTargetPlatform');
    }
    if (!_isMobile) {
      if (kDebugMode) debugPrint('[FCM] 모바일 아님 — 종료');
      return;
    }

    await _initLocalNotifications();
    await _requestPermission();
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _registerToken());
    await _registerToken();

    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) {
        debugPrint('[FCM] onMessage fired: ${message.notification?.title}');
      }

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

    // 매칭되는 상세 경로가 없는 알림은 알림함으로 보낸다.
    if (!await _navigateFromData(message.data)) {
      router.push(AppRoutes.notifications);
    }
  }

  /// 알림함 목록에서 알림을 탭했을 때 해당 상세 페이지로 이동한다.
  ///
  /// 푸시 탭(_navigateFromData)과 동일한 라우팅 규칙을 공유해 두 진입점의
  /// 동작을 일치시킨다. 단, 호출 시점에 이미 알림함 화면에 있으므로
  /// 매칭되는 경로가 없으면 (푸시 탭과 달리) 아무것도 하지 않는다.
  Future<void> openNotification({
    required String type,
    required String targetType,
    required int targetId,
  }) async {
    await _navigateFromData({
      'type': type,
      'targetType': targetType,
      'targetId': targetId.toString(),
    });
  }

  /// FCM data 맵을 기반으로 적절한 페이지로 이동한다.
  /// 포그라운드 로컬 알림 탭 / 백그라운드·종료 푸시 탭 / 알림함 목록 탭이
  /// 모두 이 함수를 사용한다. 이동했으면 true, 매칭 경로가 없으면 false 반환.
  Future<bool> _navigateFromData(Map<String, dynamic> data) async {
    // 관리자 전용 알림 (신고·인증 요청·관리자 문의)
    if (await _navigateAdminNotification(data)) {
      return true;
    }

    // 채팅 알림 — 해당 채팅방으로 이동한다.
    if (_isChatMessage(data)) {
      final roomId = int.tryParse(data['targetId'] ?? '');
      if (roomId != null) {
        await _navigateToChatRoom(roomId);
      } else {
        router.push(AppRoutes.chat);
      }
      return true;
    }

    // 문의 답변 알림 — 해당 문의 상세 페이지로 이동한다.
    if (data['type'] == 'INQUIRY' || data['targetType'] == 'INQUIRY') {
      final inquiryId = int.tryParse(data['targetId'] ?? '');
      if (inquiryId != null) {
        router.push(AppRoutes.inquiryDetail(inquiryId));
        return true;
      }
    }

    // 경고 알림 — 내 경고 내역 페이지로 이동한다.
    if (data['type'] == 'WARNING' || data['targetType'] == 'WARNING') {
      router.push(AppRoutes.myWarnings);
      return true;
    }

    // 이용 제재 알림 — 내 제재 내역 페이지로 이동한다.
    if (data['type'] == 'PENALTY' || data['targetType'] == 'PENALTY') {
      router.push(AppRoutes.myPenalties);
      return true;
    }

    // 학교 인증 결과 알림 — 인증 상태가 바뀌었으므로 랜딩부터 다시 진입해
    // 인증 플로우(대기/거절/홈)가 현재 상태에 맞는 화면으로 분기하도록 한다.
    if (data['type'] == 'VERIFICATION_APPROVED' ||
        data['type'] == 'VERIFICATION_REJECTED') {
      router.go('/');
      return true;
    }

    // 그 외 게시글 관련 알림(댓글·대댓글·좋아요 등)은 해당 게시글로 이동한다.
    // 주의: 새 알림 타입을 추가할 때는 targetId가 게시글 id로 오인되지 않도록
    // 반드시 이 분기보다 위에 명시적 분기를 추가할 것.
    final targetIdStr = data['targetId'];
    if (targetIdStr != null) {
      final postId = int.tryParse(targetIdStr);
      if (postId != null) {
        router.push('/post/$postId');
        return true;
      }
    }

    return false;
  }

  Future<bool> _navigateAdminNotification(Map<String, dynamic> data) async {
    final role = await TokenStorage().getUserRole();
    if (role != 'ADMIN') return false;

    final type = data['type'];
    final targetType = data['targetType'];
    final targetId = int.tryParse(data['targetId'] ?? '');

    if (type == 'ADMIN_REPORT' || targetType == 'REPORT') {
      if (targetId != null) {
        router.push(AppRoutes.adminReportDetail(targetId));
      } else {
        router.push(AppRoutes.adminReportList);
      }
      return true;
    }

    if (type == 'ADMIN_VERIFICATION' || targetType == 'VERIFICATION_REQUEST') {
      if (targetId != null) {
        router.push('${AppRoutes.adminVerificationList}/$targetId');
      } else {
        router.push(AppRoutes.adminVerificationList);
      }
      return true;
    }

    if (type == 'ADMIN_INQUIRY') {
      if (targetId != null) {
        router.push(AppRoutes.adminInquiryDetail(targetId));
      } else {
        router.push(AppRoutes.adminInquiries);
      }
      return true;
    }

    return false;
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

  // 게시글 상세 페이지와 연결되는 알림 타입 (targetId = postId)
  static const _postRelatedTypes = {
    'COMMENT',
    'REPLY',
    'POST_LIKE',
    'COMMENT_LIKE',
  };

  /// 사용자가 현재 알림 대상 페이지를 보고 있으면 true 반환
  bool _isUserOnRelevantPage(Map<String, dynamic> data) {
    try {
      final activePage = _ref.read(activePageProvider);
      final targetId = int.tryParse(data['targetId'] ?? '');
      if (targetId == null) return false;

      if (_isChatMessage(data)) {
        return activePage.chatRoomId == targetId;
      }

      // 댓글·대댓글·좋아요 등 게시글 관련 알림.
      // 경고/제재/인증 등 다른 타입은 targetId가 게시글 id가 아니므로
      // 우연히 번호가 같은 게시글을 보고 있어도 알림을 생략하면 안 된다.
      if (_postRelatedTypes.contains(data['type'])) {
        return activePage.postId == targetId;
      }

      return false;
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
    // 상태바 small icon은 흰색 실루엣 전용 아이콘을 사용 (풀컬러 아이콘은 덩어리로 보임)
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
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
          // 매칭되는 상세 경로가 없는 알림은 알림함으로 보낸다. (푸시 탭과 동일)
          if (!await _navigateFromData(data)) {
            router.push(AppRoutes.notifications);
          }
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
    if (kDebugMode) {
      debugPrint('[FCM] notification channel created: $_channelId');
    }
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
          // 포그라운드에서는 payload 라우팅을 유지하기 위해 로컬 알림을 사용한다.
          // iOS 시스템 표시까지 활성화하면 동일 알림이 중복으로 노출된다.
          alert: false,
          badge: false,
          sound: false,
        );
  }

  Future<void> _registerToken() async {
    if (kDebugMode) debugPrint('[FCM] 토큰 요청 중...');
    if (Platform.isIOS && !await _waitForApnsToken()) {
      if (kDebugMode) debugPrint('[FCM] APNs 토큰 대기 시간 초과');
      return;
    }

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM ERROR] 토큰 발급 실패: $e');
      return;
    }
    if (token == null) return;

    final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await _api.registerPushToken(token, platform);
        if (kDebugMode) debugPrint('[FCM] 서버 토큰 등록 완료 (시도 $attempt)');
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM ERROR] 서버 등록 실패 (시도 $attempt): $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  Future<bool> _waitForApnsToken() async {
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        if (await FirebaseMessaging.instance.getAPNSToken() != null) {
          return true;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] APNs 토큰 확인 실패: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
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
