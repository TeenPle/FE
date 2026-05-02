import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_room_model.dart';
import '../provider/chat_room_list_provider.dart';
import '../provider/muted_rooms_provider.dart';

class ChatRoomListPage extends ConsumerStatefulWidget {
  const ChatRoomListPage({super.key});

  @override
  ConsumerState<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends ConsumerState<ChatRoomListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    Future.microtask(() {
      ref.read(chatRoomListProvider.notifier).load();
      // 채팅 목록 화면에서는 유저별 STOMP 이벤트를 받아 새 메시지/읽음 상태를 즉시 반영한다.
      ref.read(chatRoomListProvider.notifier).startRealtime();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // displayName 또는 마지막 메시지 미리보기로 클라이언트 사이드 필터링
  List<ChatRoomModel> _filtered(List<ChatRoomModel> rooms) {
    if (_searchQuery.isEmpty) return rooms;
    return rooms
        .where((r) =>
            r.displayName.toLowerCase().contains(_searchQuery) ||
            r.lastPreview.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomListProvider);
    final filtered = _filtered(state.rooms);

    return Scaffold(
      backgroundColor: const Color(0xFFECF6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '채팅',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '대화방 검색',
                  hintStyle: TextStyle(fontSize: 15, color: Color(0xFFB0BEC5)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFFB0BEC5),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
                style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
              ),
            ),
          ),

          // 채팅방 목록
          Expanded(
            child: state.isLoading && state.rooms.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(chatRoomListProvider.notifier).load(),
                    child: filtered.isEmpty
                        ? _EmptyView(
                            errorMessage: state.errorMessage,
                            isSearch: _searchQuery.isNotEmpty,
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _ChatRoomItem(
                                room: filtered[index],
                                // 채팅방에서 돌아오면 목록 갱신해서 읽음 뱃지 제거
                                onReturn: () =>
                                    ref.read(chatRoomListProvider.notifier).load(),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String? errorMessage;
  final bool isSearch;

  const _EmptyView({this.errorMessage, this.isSearch = false});

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
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 38,
                  color: Color(0xFF1DA1F2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSearch
                    ? '검색 결과가 없어요.'
                    : errorMessage != null
                        ? '채팅 목록을 불러오지 못했습니다.'
                        : '아직 채팅이 없어요.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearch
                    ? '다른 검색어를 입력해보세요.'
                    : '게시글이나 댓글에서 채팅을 시작해보세요!',
                style: const TextStyle(
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

class _ChatRoomItem extends ConsumerWidget {
  final ChatRoomModel room;
  final VoidCallback onReturn;

  const _ChatRoomItem({required this.room, required this.onReturn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(mutedRoomsProvider).contains(room.roomId);
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            // 원형 아바타
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF1DA1F2),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // 채팅방 이름 + 마지막 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 채팅방 이름 + 알림 OFF 시 꺼진 종 아이콘
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
                      if (isMuted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.notifications_off_rounded,
                          size: 14,
                          color: Color(0xFF9AA7B2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
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
                            color: Color(0xFFB0BEC5),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            room.lastPreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9AA7B2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 시간 + 읽지 않은 수 뱃지 (우측 세로 정렬)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(room.lastMessageAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9AA7B2),
                  ),
                ),
                const SizedBox(height: 4),
                if (room.unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DA1F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (room.blocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '차단',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
              ],
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
