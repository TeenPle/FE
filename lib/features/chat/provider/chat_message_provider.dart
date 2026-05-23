import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../../../core/auth/auth_session_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/base_url.dart';
import '../../../core/storage/token_storage.dart';
import '../../penalty/provider/penalty_provider.dart';
import '../api/chat_api.dart';
import '../models/chat_message_model.dart';
import 'chat_room_list_provider.dart';

class ChatRoomState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isSending;
  final bool isConnected;
  final String? errorMessage;
  // 상대방이 마지막으로 읽은 메시지 ID (카카오톡 "1" 기준)
  final int? otherLastReadMessageId;
  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedByOther;
  final bool otherUserDeleted;
  final bool canSendMessage;
  final bool canReport;
  final bool canBlock;
  final bool isPenalized;
  final DateTime? penaltyExpiresAt;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isSending = false,
    this.isConnected = false,
    this.errorMessage,
    this.otherLastReadMessageId,
    this.isBlocked = false,
    this.blockedByMe = false,
    this.blockedByOther = false,
    this.otherUserDeleted = false,
    this.canSendMessage = true,
    this.canReport = true,
    this.canBlock = true,
    this.isPenalized = false,
    this.penaltyExpiresAt,
  });

  ChatRoomState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isSending,
    bool? isConnected,
    String? errorMessage,
    int? otherLastReadMessageId,
    bool? isBlocked,
    bool? blockedByMe,
    bool? blockedByOther,
    bool? otherUserDeleted,
    bool? canSendMessage,
    bool? canReport,
    bool? canBlock,
    bool? isPenalized,
    DateTime? penaltyExpiresAt,
    bool clearPenaltyExpiresAt = false,
    bool clearOtherLastRead = false,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage,
      otherLastReadMessageId: clearOtherLastRead
          ? null
          : (otherLastReadMessageId ?? this.otherLastReadMessageId),
      isBlocked: isBlocked ?? this.isBlocked,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedByOther: blockedByOther ?? this.blockedByOther,
      otherUserDeleted: otherUserDeleted ?? this.otherUserDeleted,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      canReport: canReport ?? this.canReport,
      canBlock: canBlock ?? this.canBlock,
      isPenalized: isPenalized ?? this.isPenalized,
      penaltyExpiresAt: clearPenaltyExpiresAt
          ? null
          : (penaltyExpiresAt ?? this.penaltyExpiresAt),
    );
  }
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final ChatApi _api;
  final TokenStorage _tokenStorage;
  final Ref _ref;
  final int roomId;
  final int otherUserId;
  int? _currentUserId;
  bool _isReconnectScheduled = false;
  bool _isDisposed = false;

  StompClient? _stompClient;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribe;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribeUserRooms;
  Timer? _reconnectTimer;

  ChatRoomNotifier({
    required ChatApi api,
    required TokenStorage tokenStorage,
    required Ref ref,
    required this.roomId,
    required this.otherUserId,
    required int? currentUserId,
  }) : _api = api,
       _tokenStorage = tokenStorage,
       _ref = ref,
       _currentUserId = currentUserId,
       super(const ChatRoomState());

  // 최초 입장: 히스토리 로드 + WebSocket 연결
  Future<void> init() async {
    await _loadPenaltyState();
    if (!mounted) return;
    await loadMessages();
    if (!mounted) return;
    // 자동 로그인 복원 타이밍에 세션 userId가 비어 있어도 유저별 방 이벤트를 구독한다.
    _currentUserId ??= await _tokenStorage.getUserId();
    if (!mounted) return;
    await _connectStomp();
  }

  Future<void> _loadPenaltyState() async {
    try {
      await _ref.read(activePenaltyProvider.notifier).load();
      final penalty = _ref.read(activePenaltyProvider).penalty;
      if (!mounted) return;
      state = state.copyWith(
        isPenalized: penalty?.penalized == true,
        penaltyExpiresAt: penalty?.expiresAt,
        clearPenaltyExpiresAt: penalty?.expiresAt == null,
      );
    } catch (_) {
      if (!mounted) return;
      // 제재 조회 실패 시 이전 상태를 유지한다.
      // false로 초기화하면 제재 중인 유저가 서버 측 오류 상황을 이용해 차단을 우회할 수 있다.
      // 서버는 전송 시 독립적으로 제재를 재검증하지만, FE 상태도 안전하게 유지한다.
    }
  }

  void setBlockState({
    required bool blocked,
    required bool blockedByMe,
    required bool blockedByOther,
    bool otherUserDeleted = false,
    bool canSendMessage = true,
    bool canReport = true,
    bool canBlock = true,
  }) {
    state = state.copyWith(
      isBlocked: blocked,
      blockedByMe: blockedByMe,
      blockedByOther: blockedByOther,
      otherUserDeleted: otherUserDeleted,
      canSendMessage: canSendMessage && !blocked && !otherUserDeleted,
      canReport: canReport && !otherUserDeleted,
      canBlock: canBlock && !otherUserDeleted,
    );
  }

  // HTTP로 기존 메시지 히스토리 로드
  Future<void> loadMessages({bool markAsRead = true}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _api.getMessages(roomId);
      if (!mounted) return;
      final sorted = result.messages.reversed.toList();
      state = state.copyWith(
        messages: sorted,
        isLoading: false,
        hasMore: result.messages.length == 50,
        otherLastReadMessageId: result.otherLastReadMessageId,
        isBlocked: result.blocked,
        blockedByMe: result.blockedByMe,
        blockedByOther: result.blockedByOther,
        otherUserDeleted: result.otherUserDeleted,
        canSendMessage: result.canSendMessage,
        canReport: result.canReport,
        canBlock: result.canBlock,
      );

      if (markAsRead && sorted.isNotEmpty) {
        await _api.markRead(roomId, sorted.last.messageId);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadOlderMessages() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.messages.isEmpty) {
      return;
    }

    final oldestId = state.messages.first.messageId;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final result = await _api.getMessages(roomId, lastId: oldestId);
      if (!mounted) return;

      final older = result.messages.reversed.toList();
      final existingIds = state.messages.map((m) => m.messageId).toSet();
      final mergedOlder = older
          .where((m) => !existingIds.contains(m.messageId))
          .toList();

      state = state.copyWith(
        messages: [...mergedOlder, ...state.messages],
        isLoadingMore: false,
        hasMore: result.messages.length == 50,
        otherLastReadMessageId: result.otherLastReadMessageId,
        isBlocked: result.blocked,
        blockedByMe: result.blockedByMe,
        blockedByOther: result.blockedByOther,
        otherUserDeleted: result.otherUserDeleted,
        canSendMessage: result.canSendMessage,
        canReport: result.canReport,
        canBlock: result.canBlock,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  // STOMP WebSocket 연결
  Future<void> _connectStomp() async {
    final accessToken = await _getFreshAccessToken();
    if (!mounted || accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(isConnected: false);
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: '$wsBaseUrl/ws',
        // CONNECT 헤더로 JWT 전달
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        reconnectDelay: Duration.zero,
        onConnect: _onConnect,
        onDisconnect: (_) {
          // dispose 후 콜백이 늦게 들어오면 state 접근 시 에러가 나므로 방어
          if (_isDisposed) return;
          state = state.copyWith(isConnected: false);
          _scheduleReconnect();
        },
        onStompError: (StompFrame frame) {
          debugPrint('[STOMP] error: ${frame.body}');
          if (_isDisposed) return;
          state = state.copyWith(isConnected: false);
          _scheduleReconnect(refreshTokenFirst: true);
        },
        onWebSocketError: (dynamic error) {
          // Flutter Web에서는 WebSocket 오류가 JS Event로 전달되어 [object Event]로 출력됨
          debugPrint('[STOMP] ws error: ${error.runtimeType} / $error');
          if (_isDisposed) return;
          state = state.copyWith(
            isConnected: false,
            errorMessage: '서버 연결에 실패했어요.',
          );
          _scheduleReconnect(refreshTokenFirst: true);
        },
      ),
    );
    _stompClient!.activate();
  }

  Future<String?> _getFreshAccessToken({bool refreshTokenFirst = false}) async {
    if (refreshTokenFirst) {
      try {
        final latestMessageId = state.messages.isNotEmpty
            ? state.messages.last.messageId
            : null;
        if (latestMessageId != null) {
          await _api.markRead(roomId, latestMessageId);
        } else {
          await _api.getMessages(roomId);
        }
      } catch (_) {
        // refresh 실패 처리는 Dio 인터셉터가 담당한다.
      }
    }

    final sessionToken = _ref.read(authSessionProvider).accessToken;
    if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;
    return _tokenStorage.getAccessToken();
  }

  void _scheduleReconnect({bool refreshTokenFirst = false}) {
    if (_isDisposed || !mounted || _isReconnectScheduled) return;
    _isReconnectScheduled = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      _isReconnectScheduled = false;
      if (_isDisposed || !mounted) return;
      _unsubscribe?.call();
      _unsubscribeUserRooms?.call();
      _unsubscribe = null;
      _unsubscribeUserRooms = null;
      _stompClient?.deactivate();
      _stompClient = null;
      if (_isDisposed || !mounted) return;
      final token = await _getFreshAccessToken(
        refreshTokenFirst: refreshTokenFirst,
      );
      if (token == null || token.isEmpty) return;
      await _connectStomp();
    });
  }

  // 연결 성공 시: 채팅방 구독
  void _onConnect(StompFrame frame) {
    // dispose 후 재연결 콜백이 뒤늦게 들어오는 경우 방어
    if (_isDisposed) return;
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
    if (_isDisposed || !mounted) return;
    if (frame.body == null) return;
    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final result = json['result'];
      if (result is! Map<String, dynamic>) return;

      final updatedRoomId = (result['roomId'] as num?)?.toInt();
      final eventType = (result['eventType'] ?? result['type']) as String?;

      if (updatedRoomId != roomId) return;

      if (eventType == 'ROOM_STATE_UPDATED' || eventType == 'ROOM_UPDATED') {
        if (_isDisposed || !mounted) return;
        loadMessages(markAsRead: false);
      }
    } catch (e) {
      debugPrint('[STOMP] room event parse error: $e');
    }
  }

  // 실시간 메시지 수신
  void _onMessage(StompFrame frame) {
    if (_isDisposed || !mounted) return;
    if (frame.body == null) return;
    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final result = json['result'];
      if (result == null) return;

      final resultMap = result as Map<String, dynamic>;

      final eventType =
          (resultMap['eventType'] ?? resultMap['type']) as String?;

      // SEND_ERROR: 내가 보낸 STOMP 메시지가 서버에서 거절된 경우 전송 상태를 종료한다.
      // 예: 상대방 또는 내가 차단한 채팅방에서 메시지를 보낸 경우.
      if (eventType == 'SEND_ERROR') {
        final senderId = (resultMap['senderId'] as num?)?.toInt();
        if (senderId != null && senderId != otherUserId) {
          if (_isDisposed || !mounted) return;
          state = state.copyWith(
            isSending: false,
            errorMessage: resultMap['message'] as String? ?? '메시지를 보낼 수 없어요.',
          );
          // 차단 직후 이벤트를 놓쳤더라도 서버 거절을 받으면 방 상태를 다시 맞춘다.
          loadMessages();
        }
        return;
      }

      // READ_RECEIPT: 상대방이 읽음 처리했을 때 "1" 제거
      if (eventType == 'READ_RECEIPT') {
        final readerId = (resultMap['readerId'] as num?)?.toInt();
        final lastReadId = (resultMap['lastReadMessageId'] as num?)?.toInt();
        // 상대방이 읽은 경우에만 업데이트 (내 read 이벤트는 무시)
        if (readerId == otherUserId && lastReadId != null) {
          if (_isDisposed || !mounted) return;
          state = state.copyWith(otherLastReadMessageId: lastReadId);
        }
        return;
      }

      // MESSAGE_CREATED는 신규 서버 이벤트 포맷이고, 기존 raw 메시지 포맷도 하위 호환한다.
      final messageJson = eventType == 'MESSAGE_CREATED'
          ? resultMap['message'] as Map<String, dynamic>?
          : resultMap;
      if (messageJson == null) return;

      final msg = ChatMessageModel.fromJson(messageJson);

      // 이미 같은 ID가 있으면 중복 추가 방지
      if (state.messages.any((m) => m.messageId == msg.messageId)) return;

      if (_isDisposed || !mounted) return;
      _appendMessageIfAbsent(msg);

      // 내가 채팅방 안에 있을 때 받은 상대방 메시지만 읽음 처리한다.
      // 내가 보낸 메시지를 다시 수신한 브로드캐스트에는 read 이벤트를 보내지 않는다.
      if (msg.senderId == otherUserId) {
        _api.markRead(roomId, msg.messageId).catchError((_) {});
      }
    } catch (e) {
      debugPrint('[STOMP] message parse error: $e');
    }
  }

  // 메시지 전송은 HTTP 저장 응답으로 완료 처리하고, WebSocket은 수신/갱신 전용으로 사용한다.
  // STOMP SEND echo에 전송 상태를 의존하면 Redis pub/sub 지연이나 연결 문제에서 로딩이 풀리지 않는다.
  void _appendMessageIfAbsent(ChatMessageModel msg) {
    if (_isDisposed || !mounted) return;
    if (state.messages.any((m) => m.messageId == msg.messageId)) {
      state = state.copyWith(isSending: false);
      return;
    }

    state = state.copyWith(
      messages: [...state.messages, msg],
      isSending: false,
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.isPenalized) {
      state = state.copyWith(errorMessage: _penaltyMessage());
      return;
    }
    if (state.isBlocked) {
      state = state.copyWith(errorMessage: '현재 이 채팅방에서는 메시지를 보낼 수 없어요.');
      return;
    }
    if (!state.canSendMessage || state.otherUserDeleted) {
      state = state.copyWith(errorMessage: '탈퇴한 사용자와는 채팅할 수 없어요.');
      return;
    }
    state = state.copyWith(isSending: true, errorMessage: null);

    await _sendTextByHttp(content.trim());
  }

  Future<void> _sendTextByHttp(String content) async {
    try {
      final msg = await _api.sendMessage(roomId, content);
      if (_isDisposed || !mounted) return;
      _appendMessageIfAbsent(msg);
    } catch (e) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(
        isSending: false,
        errorMessage: e is ApiException
            ? e.message
            : '메시지를 보낼 수 없어요. 상대방이 차단했거나 채팅방을 사용할 수 없어요.',
      );
    }
  }

  Future<bool> sendImage(MultipartFile file) async {
    if (state.isPenalized) {
      state = state.copyWith(errorMessage: _penaltyMessage());
      return false;
    }
    if (state.isBlocked) {
      state = state.copyWith(errorMessage: '현재 이 채팅방에서는 메시지를 보낼 수 없어요.');
      return false;
    }
    state = state.copyWith(isSending: true, errorMessage: null);

    try {
      final uploaded = await _api.uploadImage(file);
      if (_isDisposed || !mounted) return false;
      final msg = await _api.sendImageMessage(roomId, uploaded.mediaId);
      if (_isDisposed || !mounted) return false;
      _appendMessageIfAbsent(msg);
      return true;
    } catch (e) {
      if (_isDisposed || !mounted) return false;
      state = state.copyWith(
        isSending: false,
        errorMessage: e is ApiException
            ? e.message
            : '이미지를 보낼 수 없어요. 파일 형식 또는 이미지 내용을 확인해 주세요.',
      );
      return false;
    }
  }

  String _penaltyMessage() {
    final expiresAt = state.penaltyExpiresAt;
    if (expiresAt == null) {
      return '현재 정지 중이라 채팅을 사용할 수 없어요.';
    }
    final local = expiresAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '현재 정지 중이라 채팅을 사용할 수 없어요. 해제: $month.$day $hour:$minute';
  }

  Future<void> blockRoom() async {
    if (!state.canBlock || state.otherUserDeleted) return;
    await _api.block(roomId);
    if (_isDisposed || !mounted) return;
    state = state.copyWith(
      isBlocked: true,
      blockedByMe: true,
      blockedByOther: state.blockedByOther,
      canSendMessage: false,
    );
  }

  Future<void> unblockRoom() async {
    await _api.unblock(roomId);
    if (_isDisposed || !mounted) return;
    state = state.copyWith(
      isBlocked: state.blockedByOther,
      blockedByMe: false,
      blockedByOther: state.blockedByOther,
      canSendMessage: !state.blockedByOther && !state.otherUserDeleted,
    );
  }

  Future<void> reportRoom(String reason) async {
    if (!state.canReport || state.otherUserDeleted) return;
    await _api.report(roomId, reason);
  }

  Future<void> leaveRoom() async {
    await _api.leave(roomId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _unsubscribe?.call();
    _unsubscribeUserRooms?.call();
    _stompClient?.deactivate();
    super.dispose();
  }
}

// family 키: (roomId, otherUserId) — otherUserId로 READ_RECEIPT 발신자 구분
final chatRoomProvider = StateNotifierProvider.autoDispose
    .family<ChatRoomNotifier, ChatRoomState, (int, int)>((ref, key) {
      final (roomId, otherUserId) = key;
      final api = ref.read(chatApiProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final session = ref.read(authSessionProvider);
      return ChatRoomNotifier(
        api: api,
        tokenStorage: tokenStorage,
        ref: ref,
        roomId: roomId,
        otherUserId: otherUserId,
        currentUserId: session.userId,
      );
    });
