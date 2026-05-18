import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 사용자가 현재 보고 있는 페이지 정보.
/// FCM 알림 억제 판단에 사용한다 — 해당 페이지를 열고 있으면 알림을 띄우지 않는다.
class ActivePage {
  final int? chatRoomId;
  final int? postId;

  const ActivePage({this.chatRoomId, this.postId});

  static const none = ActivePage();
}

final activePageProvider = StateProvider<ActivePage>((_) => const ActivePage());
