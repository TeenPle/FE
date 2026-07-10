import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
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
      ref.read(chatRoomListProvider.notifier).startRealtime();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatRoomModel> _filtered(List<ChatRoomModel> rooms) {
    if (_searchQuery.isEmpty) return rooms;
    return rooms
        .where(
          (r) =>
              r.roomTitle.toLowerCase().contains(_searchQuery) ||
              r.counterpartDisplayName.toLowerCase().contains(_searchQuery) ||
              r.lastPreview.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomListProvider);
    final filtered = _filtered(state.rooms);
    final chatUnreadCount = state.rooms.fold(
      0,
      (sum, room) => sum + room.unreadCount,
    );

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        chatUnreadCount: chatUnreadCount,
        onTap: (index) => _goMainTab(context, index),
      ),
      appBar: AppBar(
        backgroundColor: c.cardBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          '채팅',
          style: AppTextStyles.displaySmall.copyWith(color: c.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: c.inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '채팅방 검색',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: c.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: c.textMuted,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
              ),
            ),
          ),
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
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _ChatRoomItem(
                                room: filtered[index],
                                onReturn: () => ref
                                    .read(chatRoomListProvider.notifier)
                                    .load(),
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

void _goMainTab(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutes.school);
      return;
    case 1:
      return;
    case 2:
      context.go(AppRoutes.meal);
      return;
    case 3:
      context.go(AppRoutes.timetable);
      return;
    case 4:
      context.go(AppRoutes.profile);
      return;
  }
}

class _EmptyView extends StatelessWidget {
  final String? errorMessage;
  final bool isSearch;

  const _EmptyView({this.errorMessage, this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                    ? '검색 결과가 없어요'
                    : errorMessage != null
                    ? '채팅 목록을 불러오지 못했어요.'
                    : '아직 채팅이 없어요',
                style: AppTextStyles.titleSmall.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                isSearch ? '다른 검색어를 입력해보세요.' : '게시글이나 댓글에서 채팅을 시작해보세요.',
                style: AppTextStyles.captionLarge.copyWith(color: c.textMuted),
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
    final c = context.colors;
    final roomTitle = room.roomTitle.trim().isEmpty
        ? '채팅방'
        : room.roomTitle.trim();
    final counterpartName = room.counterpartDisplayName.trim().isEmpty
        ? '상대방'
        : room.counterpartDisplayName.trim();

    return GestureDetector(
      onTap: () async {
        await context.push(
          '/chat/rooms/${room.roomId}',
          extra: {
            'otherUserId': room.otherUserId,
            'displayName': roomTitle,
            'roomTitle': roomTitle,
            'counterpartDisplayName': counterpartName,
            'counterpartProfileImageUrl': room.counterpartProfileImageUrl,
            'blocked': room.blocked,
            'blockedByMe': room.blockedByMe,
            'blockedByOther': room.blockedByOther,
            'otherUserDeleted': room.otherUserDeleted,
            'canSendMessage': room.canSendMessage,
            'canReport': room.canReport,
            'canBlock': room.canBlock,
          },
        );
        onReturn();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.cardBg,
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
            _Avatar(
              imageUrl: room.counterpartProfileImageUrl,
              deleted: room.otherUserDeleted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          roomTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: room.otherUserDeleted
                                ? c.textMuted
                                : c.textPrimary,
                          ),
                        ),
                      ),
                      if (room.otherUserDeleted) ...[
                        const SizedBox(width: 4),
                        _StatusChip(label: '탈퇴', muted: true),
                      ] else if (isMuted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.notifications_off_rounded,
                          size: 14,
                          color: c.textMuted,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          room.otherUserDeleted ? '탈퇴한 사용자' : counterpartName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 12,
                            color: room.otherUserDeleted
                                ? c.textMuted
                                : const Color(0xFF1DA1F2),
                          ),
                        ),
                      ),
                      if (room.lastPreview.isNotEmpty) ...[
                        Text(
                          '  ·  ',
                          style: AppTextStyles.captionSmall.copyWith(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            room.lastPreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionSmall.copyWith(
                              fontSize: 12,
                              color: c.textMuted,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(room.lastMessageAt),
                  style: AppTextStyles.captionSmall.copyWith(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                if (room.unreadCount > 0)
                  _UnreadBadge(count: room.unreadCount)
                else if (room.blocked)
                  _StatusChip(label: '차단', muted: true),
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

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final bool deleted;

  const _Avatar({required this.imageUrl, required this.deleted});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: deleted ? c.subtleBg : const Color(0xFFE3F2FD),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _AvatarIcon(deleted: deleted),
            )
          : _AvatarIcon(deleted: deleted),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final bool deleted;

  const _AvatarIcon({required this.deleted});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Icon(
      Icons.person_rounded,
      color: deleted ? c.textMuted : const Color(0xFF1DA1F2),
      size: 28,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1DA1F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool muted;

  const _StatusChip({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: muted ? c.textTertiary : c.textBody,
        ),
      ),
    );
  }
}
