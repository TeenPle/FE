import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

// 메시지 목록 + 상대방 읽음 위치를 함께 반환
class ChatMessageListResult {
  final List<ChatMessageModel> messages;
  final int? otherLastReadMessageId;
  final bool blocked;
  final bool blockedByMe;
  final bool blockedByOther;

  const ChatMessageListResult({
    required this.messages,
    this.otherLastReadMessageId,
    this.blocked = false,
    this.blockedByMe = false,
    this.blockedByOther = false,
  });
}

class ChatApi {
  final AppApiClient _client;

  const ChatApi(this._client);

  Future<ChatImageUploadResult> uploadImage(MultipartFile file) async {
    final json = await _client.postMultipartFile('/api/chat/images', file: file);
    final resp = ApiResponse.fromJson(
      json,
      (data) => ChatImageUploadResult.fromJson(data as Map<String, dynamic>),
    );
    if (!resp.isSuccess || resp.result == null) throw Exception(resp.message);
    return resp.result!;
  }

  // 게시글 기반 1:1 채팅방 생성/조회
  Future<Map<String, dynamic>> createOrGetDm({
    required int otherUserId,
    required int sourcePostId,
    required String roomTitle,
  }) async {
    final json = await _client.post('/api/chat/rooms/dm', body: {
      'otherUserId': otherUserId,
      'sourcePostId': sourcePostId,
      'roomTitle': roomTitle,
    });

    final resp = ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
    if (!resp.isSuccess || resp.result == null) throw Exception(resp.message);
    return resp.result!;
  }

  // 내 채팅방 목록 조회
  Future<List<ChatRoomModel>> getMyRooms() async {
    final json = await _client.get('/api/chat/rooms');
    final resp = ApiResponse.fromJson(json, (data) {
      final map = data as Map<String, dynamic>;
      return (map['rooms'] as List<dynamic>)
          .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    if (!resp.isSuccess || resp.result == null) throw Exception(resp.message);
    return resp.result!;
  }

  // 채팅방 메시지 조회 (상대방 읽음 위치 포함)
  Future<ChatMessageListResult> getMessages(int roomId, {int? lastId}) async {
    final json = await _client.get(
      '/api/chat/rooms/$roomId/messages',
      queryParameters: lastId != null ? {'lastId': '$lastId'} : null,
    );
    final resp = ApiResponse.fromJson(json, (data) {
      final map = data as Map<String, dynamic>;
      final messages = (map['messages'] as List<dynamic>)
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final otherLastRead = map['otherLastReadMessageId'] != null
          ? (map['otherLastReadMessageId'] as num).toInt()
          : null;
      return ChatMessageListResult(
        messages: messages,
        otherLastReadMessageId: otherLastRead,
        blocked: map['blocked'] as bool? ?? false,
        blockedByMe: map['blockedByMe'] as bool? ?? false,
        blockedByOther: map['blockedByOther'] as bool? ?? false,
      );
    });
    if (!resp.isSuccess || resp.result == null) throw Exception(resp.message);
    return resp.result!;
  }

  // 메시지 전송 (HTTP fallback)
  Future<ChatMessageModel> sendMessage(int roomId, String content) async {
    final json = await _client.post('/api/chat/rooms/$roomId/messages', body: {
      'roomId': roomId,
      'type': 'TEXT',
      'content': content,
    });
    final resp = ApiResponse.fromJson(
      json,
      (data) => ChatMessageModel.fromJson(data as Map<String, dynamic>),
    );
    if (!resp.isSuccess || resp.result == null) throw Exception(resp.message);
    return resp.result!;
  }

  Future<ChatMessageModel> sendImageMessage(int roomId, int mediaId) async {
    final json = await _client.post('/api/chat/rooms/$roomId/messages', body: {
      'roomId': roomId,
      'type': 'IMAGE',
      'mediaId': mediaId,
    });
    final resp = ApiResponse.fromJson(
      json,
      (data) => ChatMessageModel.fromJson(data as Map<String, dynamic>),
    );
    if (!resp.isSuccess || resp.result == null) throw Exception(resp.message);
    return resp.result!;
  }

  // 읽음 처리
  Future<void> markRead(int roomId, int messageId) async {
    await _client.post('/api/chat/rooms/$roomId/read', body: {'messageId': messageId});
  }

  // 채팅방 차단
  Future<void> block(int roomId) async {
    await _client.post('/api/chat/rooms/$roomId/block');
  }

  // 채팅방 차단 해제
  Future<void> unblock(int roomId) async {
    await _client.post('/api/chat/rooms/$roomId/unblock');
  }

  // 채팅방 신고
  Future<void> report(int roomId, String reason) async {
    await _client.post('/api/chat/rooms/$roomId/report', body: {'reason': reason});
  }

  // 채팅방 나가기
  Future<void> leave(int roomId) async {
    await _client.post('/api/chat/rooms/$roomId/leave');
  }
}

class ChatImageUploadResult {
  final int mediaId;
  final String imageUrl;

  const ChatImageUploadResult({
    required this.mediaId,
    required this.imageUrl,
  });

  factory ChatImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ChatImageUploadResult(
      mediaId: (json['mediaId'] as num).toInt(),
      imageUrl: json['imageUrl'] as String,
    );
  }
}
