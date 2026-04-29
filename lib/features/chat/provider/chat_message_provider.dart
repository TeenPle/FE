import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../../../core/auth/auth_session_provider.dart';
import '../../../core/network/base_url.dart';
import '../../../core/storage/token_storage.dart';
import '../api/chat_api.dart';
import '../models/chat_message_model.dart';
import 'chat_room_list_provider.dart';

class ChatRoomState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final bool isConnected;
  final String? errorMessage;
  // 상대방이 마지막으로 읽은 메시지 ID (카카오톡 "1" 기준)
  final int? otherLastReadMessageId;
  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedByOther;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isConnected = false,
    this.errorMessage,
    this.otherLastReadMessageId,
    this.isBlocked = false,
    this.blockedByMe = false,
    this.blockedByOther = false,
  });

  ChatRoomState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isConnected,
    String? errorMessage,
    int? otherLastReadMessageId,
    bool? isBlocked,
    bool? blockedByMe,
    bool? blockedByOther,
    bool clearOtherLastRead = false,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage,
      otherLastReadMessageId: clearOtherLastRead
          ? null
          : (otherLastReadMessageId ?? this.otherLastReadMessageId),
      isBlocked: isBlocked ?? this.isBlocked,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedByOther: blockedByOther ?? this.blockedByOther,
    );
  }
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final ChatApi _api;
  final TokenStorage _tokenStorage;
  final int roomId;
  final int otherUserId;
  final String _accessToken;
  int? _currentUserId;

  StompClient? _stompClient;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribe;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribeUserRooms;

  ChatRoomNotifier({
    required ChatApi api,
    required TokenStorage tokenStorage,
    required this.roomId,
    required this.otherUserId,
    required String accessToken,
    required int? currentUserId,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _accessToken = accessToken,
        _currentUserId = currentUserId,
        super(const ChatRoomState());

  // 최초 입장: 히스토리 로드 + WebSocket 연결
  Future<void> init() async {
    await loadMessages();
    if (!mounted) return;
    // 자동 로그인 복원 타이밍에 세션 userId가 비어 있어도 유저별 방 이벤트를 구독한다.
    _currentUserId ??= await _tokenStorage.getUserId();
    if (!mounted) return;
    _connectStomp();
  }

  void setBlockState({
    required bool blocked,
    required bool blockedByMe,
    required bool blockedByOther,
  }) {
    state = state.copyWith(
      isBlocked: blocked,
      blockedByMe: blockedByMe,
      blockedByOther: blockedByOther,
    );
  }

  // HTTP로 기존 메시지 히스토리 로드
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _api.getMessages(roomId);
      if (!mounted) return;
      final sorted = result.messages.reversed.toList();
      state = state.copyWith(
        messages: sorted,
        isLoading: false,
        otherLastReadMessageId: result.otherLastReadMessageId,
        isBlocked: result.blocked,
        blockedByMe: result.blockedByMe,
        blockedByOther: result.blockedByOther,
      );

      if (sorted.isNotEmpty) {
        await _api.markRead(roomId, sorted.last.messageId);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // STOMP WebSocket 연결
  void _connectStomp() {
    _stompClient = StompClient(
      config: StompConfig(
        url: '$wsBaseUrl/ws',
        // CONNECT 헤더로 JWT 전달
        stompConnectHeaders: {'Authorization': 'Bearer $_accessToken'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: _onConnect,
        onDisconnect: (_) {
          state = state.copyWith(isConnected: false);
        },
        onStompError: (StompFrame frame) {
          debugPrint('[STOMP] error: ${frame.body}');
          state = state.copyWith(isConnected: false);
        },
        onWebSocketError: (dynamic error) {
          // Flutter Web에서는 WebSocket 오류가 JS Event로 전달되어 [object Event]로 출력됨
          debugPrint('[STOMP] ws error: ${error.runtimeType} / $error');
          state = state.copyWith(isConnected: false, errorMessage: '서버 연결에 실패했습니다.');
        },
      ),
    );
    _stompClient!.activate();
  }

  // 연결 성공 시: 채팅방 구독
  void _onConnect(StompFrame frame) {
    state = state.copyWith(isConnected: true);
    _unsubscribe = _stompClient!.subscribe(
      destination: '/sub/chat/rooms/$roomId',
      callback: _onMessage,
    );

    if (_currentUserId != null) {
      // 차단/차단 해제는 메시지 토픽이 아니라 유저별 방 변경 이벤트로 내려온다.
      // 현재 방 이벤트만 다시 조회해서 상대가 나를 차단한 경우도 입력창을 즉시 잠근다.
      _unsubscribeUserRooms = _stompClient!.subscribe(
        destination: '/sub/chat/users/$_currentUserId/rooms',
        callback: _onRoomUpdated,
      );
    }
  }

  void _onRoomUpdated(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final result = json['result'];
      if (result is! Map<String, dynamic>) return;

      final updatedRoomId = (result['roomId'] as num?)?.toInt();
      if (result['type'] == 'ROOM_UPDATED' && updatedRoomId == roomId) {
        loadMessages();
      }
    } catch (e) {
      debugPrint('[STOMP] room event parse error: $e');
    }
  }

  // 실시간 메시지 수신
  void _onMessage(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final result = json['result'];
      if (result == null) return;

      final resultMap = result as Map<String, dynamic>;

      // SEND_ERROR: 내가 보낸 STOMP 메시지가 서버에서 거절된 경우 전송 상태를 종료한다.
      // 예: 상대방 또는 내가 차단한 채팅방에서 메시지를 보낸 경우.
      if (resultMap['type'] == 'SEND_ERROR') {
        final senderId = (resultMap['senderId'] as num?)?.toInt();
        if (senderId != null && senderId != otherUserId) {
          state = state.copyWith(
            isSending: false,
            errorMessage: resultMap['message'] as String? ?? '메시지를 보낼 수 없습니다.',
          );
          // 차단 직후 이벤트를 놓쳤더라도 서버 거절을 받으면 방 상태를 다시 맞춘다.
          loadMessages();
        }
        return;
      }

      // READ_RECEIPT: 상대방이 읽음 처리했을 때 "1" 제거
      if (resultMap['type'] == 'READ_RECEIPT') {
        final readerId = (resultMap['readerId'] as num?)?.toInt();
        final lastReadId = (resultMap['lastReadMessageId'] as num?)?.toInt();
        // 상대방이 읽은 경우에만 업데이트 (내 read 이벤트는 무시)
        if (readerId == otherUserId && lastReadId != null) {
          state = state.copyWith(otherLastReadMessageId: lastReadId);
        }
        return;
      }

      // 일반 메시지 처리
      final msg = ChatMessageModel.fromJson(resultMap);

      // 이미 같은 ID가 있으면 중복 추가 방지
      if (state.messages.any((m) => m.messageId == msg.messageId)) return;

      final updated = [...state.messages, msg];
      state = state.copyWith(messages: updated, isSending: false);

      // 내가 채팅방 안에 있을 때 받은 상대방 메시지만 읽음 처리한다.
      // 내가 보낸 메시지를 다시 수신한 브로드캐스트에는 read 이벤트를 보내지 않는다.
      if (msg.senderId == otherUserId) {
        _api.markRead(roomId, msg.messageId).catchError((_) {});
      }
    } catch (e) {
      debugPrint('[STOMP] message parse error: $e');
    }
  }

  // 메시지 전송 - WebSocket 우선, 미연결이면 HTTP fallback
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.isBlocked) {
      state = state.copyWith(errorMessage: '현재 이 채팅방에서는 메시지를 보낼 수 없습니다.');
      return;
    }
    state = state.copyWith(isSending: true, errorMessage: null);

    final payload = jsonEncode({
      'roomId': roomId,
      'type': 'TEXT',
      'content': content.trim(),
    });

    if (_stompClient != null && _stompClient!.connected) {
      // WebSocket SEND → 서버가 /sub/chat/rooms/{roomId} 로 브로드캐스트
      // → _onMessage()에서 state 업데이트됨
      _stompClient!.send(
        destination: '/pub/chat.send',
        body: payload,
      );
    } else {
      // WebSocket 미연결: HTTP fallback
      try {
        final msg = await _api.sendMessage(roomId, content.trim());
        final updated = [...state.messages, msg];
        state = state.copyWith(messages: updated, isSending: false);
      } catch (e) {
        state = state.copyWith(
          isSending: false,
          errorMessage: '메시지를 보낼 수 없습니다. 상대방이 차단했거나 채팅방을 사용할 수 없습니다.',
        );
      }
    }
  }

  Future<void> blockRoom() async {
    await _api.block(roomId);
    state = state.copyWith(
      isBlocked: true,
      blockedByMe: true,
      blockedByOther: state.blockedByOther,
    );
  }

  Future<void> unblockRoom() async {
    await _api.unblock(roomId);
    state = state.copyWith(
      isBlocked: state.blockedByOther,
      blockedByMe: false,
      blockedByOther: state.blockedByOther,
    );
  }

  Future<void> reportRoom(String reason) async {
    await _api.report(roomId, reason);
  }

  Future<void> leaveRoom() async {
    await _api.leave(roomId);
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _unsubscribeUserRooms?.call();
    _stompClient?.deactivate();
    super.dispose();
  }
}

// family 키: (roomId, otherUserId) — otherUserId로 READ_RECEIPT 발신자 구분
final chatRoomProvider = StateNotifierProvider.autoDispose.family<
    ChatRoomNotifier, ChatRoomState, (int, int)>((ref, key) {
  final (roomId, otherUserId) = key;
  final api = ref.read(chatApiProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  final session = ref.read(authSessionProvider);
  final token = session.accessToken ?? '';
  return ChatRoomNotifier(
    api: api,
    tokenStorage: tokenStorage,
    roomId: roomId,
    otherUserId: otherUserId,
    accessToken: token,
    currentUserId: session.userId,
  );
});
