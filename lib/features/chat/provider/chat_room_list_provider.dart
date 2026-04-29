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
  bool _isRealtimeStarting = false;

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

    _isRealtimeStarting = true;
    try {
      final authSession = _ref.read(authSessionProvider);
      final storage = _ref.read(tokenStorageProvider);
      final accessToken = authSession.accessToken ?? await storage.getAccessToken();
      final userId = authSession.userId ?? await storage.getUserId();

      if (accessToken == null || accessToken.isEmpty || userId == null) {
        return;
      }

      _stompClient = StompClient(
        config: StompConfig(
          url: '$wsBaseUrl/ws',
          stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
          reconnectDelay: const Duration(seconds: 5),
          onConnect: (_) => _subscribeUserRooms(userId),
          onDisconnect: (_) => debugPrint('[CHAT ROOMS] realtime disconnected'),
          onStompError: (frame) =>
              debugPrint('[CHAT ROOMS] stomp error: ${frame.body}'),
          onWebSocketError: (error) =>
              debugPrint('[CHAT ROOMS] ws error: ${error.runtimeType} / $error'),
        ),
      );
      _stompClient!.activate();
    } finally {
      _isRealtimeStarting = false;
    }
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

      // ROOM_UPDATED는 "목록이 바뀌었다"는 신호만 담당한다.
      // 실제 목록 데이터는 기존 REST API로 다시 받아 정렬/미읽음 수 정합성을 유지한다.
      if (result['type'] == 'ROOM_UPDATED') {
        _scheduleRealtimeReload();
      }
    } catch (e) {
      debugPrint('[CHAT ROOMS] event parse error: $e');
    }
  }

  void _scheduleRealtimeReload() {
    _reloadDebounceTimer?.cancel();
    _reloadDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      load();
    });
  }

  void stopRealtime() {
    _reloadDebounceTimer?.cancel();
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
