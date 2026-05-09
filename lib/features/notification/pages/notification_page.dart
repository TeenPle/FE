import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/time_format.dart';
import '../models/notification_model.dart';
import '../provider/notification_provider.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  final _scrollController = ScrollController();
  late final NotificationNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(notificationProvider.notifier);
    Future.microtask(() => _notifier.loadNotifications());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _notifier.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 페이지 떠날 때 서버에만 전체 읽음 처리 (배지 초기화)
    _notifier.markAllAsReadServerOnly();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.black87,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.notifications.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _NotificationItem(
                      notification: state.notifications[index],
                      onTap: () => _handleTap(state.notifications[index]),
                    );
                  },
                ),
    );
  }

  void _handleTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notifier.markAsRead(notification.id);
    }
    if (notification.targetType == 'POST') {
      context.push('/post/${notification.targetId}');
    }
    // COMMENT targetType은 현재 사용하지 않음 (BE가 모두 POST로 통일)
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  // boardName이 있는 알림은 모두 게시판 이름 표시 레이아웃 사용
  bool get _hasBoardName => notification.boardName != null;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isUnread ? const Color(0xFFEAF3FB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(type: notification.type),
            const SizedBox(width: 14),
            Expanded(
              child: _hasBoardName
                  ? _CommentNotificationContent(
                      notification: notification,
                      isUnread: isUnread,
                    )
                  : _DefaultNotificationContent(
                      notification: notification,
                      isUnread: isUnread,
                    ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF14A3F7),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommentNotificationContent extends StatelessWidget {
  final NotificationModel notification;
  final bool isUnread;

  const _CommentNotificationContent({
    required this.notification,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notification.boardName != null) ...[
          Text(
            notification.boardName!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14A3F7),
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          notification.message,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF111111),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          timeAgo(notification.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9AA7B2),
          ),
        ),
      ],
    );
  }
}

class _DefaultNotificationContent extends StatelessWidget {
  final NotificationModel notification;
  final bool isUnread;

  const _DefaultNotificationContent({
    required this.notification,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.message,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF111111),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeAgo(notification.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9AA7B2),
          ),
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'COMMENT':
      case 'REPLY':
        icon = Icons.chat_bubble_outline_rounded;
        color = const Color(0xFF14A3F7);
        break;
      case 'POST_LIKE':
      case 'COMMENT_LIKE':
        icon = Icons.favorite_border_rounded;
        color = const Color(0xFFE05C7B);
        break;
      case 'CHAT':
        icon = Icons.forum_outlined;
        color = const Color(0xFF4CAF7D);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = const Color(0xFF9AA7B2);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 52, color: Color(0xFFB0BEC5)),
          SizedBox(height: 16),
          Text(
            '아직 알림이 없어요',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '새 댓글이나 공감이 오면 알려드릴게요.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }
}
