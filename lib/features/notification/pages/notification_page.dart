import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_format.dart';
import '../models/notification_model.dart';
import '../provider/notification_provider.dart';
import '../service/fcm_service.dart';

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
    _notifier.markAllAsReadServerOnly();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: c.iconPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          '알림',
          style: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (context, index) {
                if (index >= state.notifications.length - 1) {
                  return const SizedBox.shrink();
                }
                return Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colors.divider,
                  indent: 74,
                  endIndent: 20,
                );
              },
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
    // 라우팅은 FCM 푸시 탭과 동일한 규칙(FcmService)에 위임한다.
    // 게시글·문의뿐 아니라 채팅/경고/제재/인증 결과/관리자 알림까지 일관되게 처리된다.
    ref
        .read(fcmServiceProvider)
        .openNotification(
          type: notification.type,
          targetType: notification.targetType,
          targetId: notification.targetId,
        );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  bool get _hasBoardName => notification.boardName != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isUnread ? c.tintBg : c.cardBg,
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notification.boardName != null) ...[
          Text(
            notification.boardName!,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          notification.message,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
            color: c.textPrimary,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          timeAgo(notification.createdAt),
          style: AppTextStyles.captionSmall.copyWith(
            fontSize: 12,
            color: c.textTertiary,
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.message,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
            color: c.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeAgo(notification.createdAt),
          style: AppTextStyles.captionSmall.copyWith(
            fontSize: 12,
            color: c.textTertiary,
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

    // 백엔드 NotificationType enum과 1:1로 대응한다.
    // 새 타입 추가 시 여기에도 케이스를 추가하지 않으면 기본 종 모양으로 표시된다.
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
      case 'INQUIRY':
        // 문의 답변
        icon = Icons.support_agent_rounded;
        color = const Color(0xFF7C5CE0);
        break;
      case 'WARNING':
        // 관리자 경고
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'PENALTY':
        // 이용 제재
        icon = Icons.block_rounded;
        color = const Color(0xFFE05C5C);
        break;
      case 'VERIFICATION_APPROVED':
        // 학교 인증 승인
        icon = Icons.verified_outlined;
        color = const Color(0xFF4CAF7D);
        break;
      case 'VERIFICATION_REJECTED':
        // 학교 인증 거절
        icon = Icons.school_outlined;
        color = const Color(0xFFE05C5C);
        break;
      case 'ADMIN_REPORT':
        // 새 신고 접수 (관리자 전용)
        icon = Icons.flag_outlined;
        color = const Color(0xFFE05C5C);
        break;
      case 'ADMIN_INQUIRY':
        // 새 문의 접수 (관리자 전용)
        icon = Icons.support_agent_rounded;
        color = const Color(0xFF7C5CE0);
        break;
      case 'ADMIN_VERIFICATION':
        // 새 학교 인증 요청 (관리자 전용)
        icon = Icons.how_to_reg_outlined;
        color = const Color(0xFF14A3F7);
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
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: c.iconSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 알림이 없어요',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '새 댓글이나 좋아요, 채팅이 오면 알려드릴게요.',
            style: AppTextStyles.captionSmall.copyWith(
              fontSize: 12,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
