import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_room_model.dart';
import '../provider/chat_room_list_provider.dart';

class ChatRoomListPage extends ConsumerStatefulWidget {
  const ChatRoomListPage({super.key});

  @override
  ConsumerState<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends ConsumerState<ChatRoomListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatRoomListProvider.notifier).load();
      // 채팅 목록 화면에서는 유저별 STOMP 이벤트를 받아 새 메시지/읽음 상태를 즉시 반영한다.
      ref.read(chatRoomListProvider.notifier).startRealtime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFECF6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECF6FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '채팅',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: state.isLoading && state.rooms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(chatRoomListProvider.notifier).load(),
              child: state.rooms.isEmpty
                  ? _EmptyView(errorMessage: state.errorMessage)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: state.rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ChatRoomItem(
                          room: state.rooms[index],
                          // 채팅방에서 돌아오면 목록 갱신해서 읽음 뱃지 제거
                          onReturn: () => ref.read(chatRoomListProvider.notifier).load(),
                        );
                      },
                    ),
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String? errorMessage;

  const _EmptyView({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 40,
                  color: Color(0xFF1DA1F2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage != null
                    ? '채팅 목록을 불러오지 못했습니다.'
                    : '아직 채팅이 없어요.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '게시글이나 댓글에서 채팅을 시작해보세요!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7D8790),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatRoomItem extends StatelessWidget {
  final ChatRoomModel room;
  final VoidCallback onReturn;

  const _ChatRoomItem({required this.room, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/chat/rooms/${room.roomId}', extra: {
          'otherUserId': room.otherUserId,
          'displayName': room.displayName,
          'blocked': room.blocked,
          'blockedByMe': room.blockedByMe,
          'blockedByOther': room.blockedByOther,
        });
        // 채팅방 읽고 돌아오면 목록 갱신 (읽음 처리 반영)
        onReturn();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 채팅 아이콘 아바타
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF1DA1F2),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // 채팅방 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(room.lastMessageAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AA7B2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        '익명',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1DA1F2),
                        ),
                      ),
                      if (room.lastPreview.isNotEmpty) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9AA7B2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            room.lastPreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7D8790),
                            ),
                          ),
                        ),
                      ],
                      if (room.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DA1F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            room.unreadCount > 99
                                ? '99+'
                                : '${room.unreadCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (room.blocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '차단',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
