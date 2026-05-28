import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../../../core/auth/auth_session_provider.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/base_url.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../api/chat_api.dart';
import '../models/chat_room_model.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatApi(AppApiClient(dio));
});

class ChatRoomListState {
  final List<ChatRoomModel> rooms;
  final bool isLoading;
  final String? errorMessage;

  const ChatRoomListState({
    this.rooms = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatRoomListState copyWith({
    List<ChatRoomModel>? rooms,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatRoomListState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatRoomListNotifier extends StateNotifier<ChatRoomListState> {
  final ChatApi _api;
  final Ref _ref;

  StompClient? _stompClient;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribe;
  Timer? _reloadDebounceTimer;
  Timer? _reconnectTimer;
  bool _isRealtimeStarting = false;
  bool _isReconnectScheduled = false;
  bool _manualStop = false;

  ChatRoomListNotifier(this._api, this._ref) : super(const ChatRoomListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rooms = await _api.getMyRooms();
      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> startRealtime() async {
    if (_isRealtimeStarting || _stompClient != null) {
      return;
    }

    _manualStop = false;
    _isRealtimeStarting = true;
    try {
      final accessToken = await _getFreshAccessToken();
      final userId =
          _ref.read(authSessionProvider).userId ??
          await _ref.read(tokenStorageProvider).getUserId();

      if (accessToken == null || accessToken.isEmpty || userId == null) {
        return;
      }

      _stompClient = StompClient(
        config: StompConfig(
          url: '$wsBaseUrl/ws',
          stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
          reconnectDelay: Duration.zero,
          onConnect: (_) => _subscribeUserRooms(userId),
          onDisconnect: (_) {
            if (kDebugMode) debugPrint('[CHAT ROOMS] realtime disconnected');
            _scheduleReconnect();
          },
          onStompError: (frame) {
            if (kDebugMode) {
              debugPrint('[CHAT ROOMS] stomp error: ${frame.body}');
            }
            _scheduleReconnect(refreshTokenFirst: true);
          },
          onWebSocketError: (error) {
            if (kDebugMode) {
              debugPrint(
                '[CHAT ROOMS] ws error: ${error.runtimeType} / $error',
              );
            }
            _scheduleReconnect(refreshTokenFirst: true);
          },
        ),
      );
      _stompClient!.activate();
    } finally {
      _isRealtimeStarting = false;
    }
  }

  Future<String?> _getFreshAccessToken({bool refreshTokenFirst = false}) async {
    if (refreshTokenFirst) {
      try {
        await _api.getMyRooms();
      } catch (_) {
        // refresh 실패 처리는 Dio 인터셉터가 담당한다.
      }
    }

    final sessionToken = _ref.read(authSessionProvider).accessToken;
    if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;
    return _ref.read(tokenStorageProvider).getAccessToken();
  }

  void _scheduleReconnect({bool refreshTokenFirst = false}) {
    if (_manualStop || _isReconnectScheduled) return;
    _isReconnectScheduled = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      _isReconnectScheduled = false;
      if (_manualStop) return;
      _unsubscribe?.call();
      _unsubscribe = null;
      _stompClient?.deactivate();
      _stompClient = null;

      final token = await _getFreshAccessToken(
        refreshTokenFirst: refreshTokenFirst,
      );
      final userId =
          _ref.read(authSessionProvider).userId ??
          await _ref.read(tokenStorageProvider).getUserId();
      if (token == null || token.isEmpty || userId == null) return;
      await startRealtime();
    });
  }

  void _subscribeUserRooms(int userId) {
    _unsubscribe?.call();
    _unsubscribe = _stompClient?.subscribe(
      destination: '/sub/chat/users/$userId/rooms',
      callback: _onRoomEvent,
    );
  }

  void _onRoomEvent(StompFrame frame) {
    if (frame.body == null) return;

    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final result = json['result'];
      if (result is! Map<String, dynamic>) return;

      final eventType = (result['eventType'] ?? result['type']) as String?;

      // 유저별 방 이벤트는 목록 재조회만 담당한다. 상세방 read 처리는 여기서 하지 않는다.
      if (eventType == 'ROOM_LIST_UPDATED' ||
          eventType == 'ROOM_STATE_UPDATED' ||
          eventType == 'ROOM_UPDATED') {
        _scheduleRealtimeReload();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CHAT ROOMS] event parse error: $e');
    }
  }

  void _scheduleRealtimeReload() {
    _reloadDebounceTimer?.cancel();
    _reloadDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      load();
    });
  }

  void stopRealtime() {
    _manualStop = true;
    _reloadDebounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _isReconnectScheduled = false;
    _unsubscribe?.call();
    _unsubscribe = null;
    _stompClient?.deactivate();
    _stompClient = null;
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}

final chatRoomListProvider =
    StateNotifierProvider<ChatRoomListNotifier, ChatRoomListState>((ref) {
      return ChatRoomListNotifier(ref.read(chatApiProvider), ref);
    });
