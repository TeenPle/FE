import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../features/dday/widgets/dday_strip.dart';
import '../../../features/notification/provider/notification_provider.dart';
import '../models/hot_filter.dart';
import '../provider/school_providers.dart';
import 'widgets/post_summary_card.dart';

/// HOT 게시판 전체 보기 페이지
class HotBoardPage extends ConsumerStatefulWidget {
  const HotBoardPage({super.key});

  @override
  ConsumerState<HotBoardPage> createState() => _HotBoardPageState();
}

class _HotBoardPageState extends ConsumerState<HotBoardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(schoolProvider.notifier).loadHotPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);
    final notifier = ref.read(schoolProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (context.canPop()) context.pop();
                        else context.go('/school');
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF111111),
                        size: 22,
                      ),
                    ),
                  ),
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔥',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'HOT 게시판',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => context.push(AppRoutes.profile),
                            icon: const Icon(
                              Icons.account_circle_outlined,
                              color: Color(0xFF111111),
                              size: 26,
                            ),
                          ),
                          _HotNotificationButton(
                            onTap: () async {
                              await context.push(AppRoutes.notifications);
                              if (context.mounted) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .loadUnreadCount();
                              }
                            },
                          ),
                          IconButton(
                            onPressed: () => context.push(AppRoutes.settings),
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF111111),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const DDayStrip(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),

          // 필터 칩
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Row(
              children: HotFilter.values.map((f) {
                final selected = state.hotFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => notifier.changeHotFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF7D8790),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),

          // 게시글 목록
          Expanded(
            child: state.isLoadingHot
                ? const Center(child: CircularProgressIndicator())
                : state.hotPosts.isEmpty
                    ? _EmptyHotState(filter: state.hotFilter)
                    : RefreshIndicator(
                        onRefresh: notifier.loadHotPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: state.hotPosts.length,
                          itemBuilder: (ctx, i) {
                            final post = state.hotPosts[i];
                            return Container(
                              color: i.isEven
                                  ? Colors.white
                                  : const Color(0xFFFAFBFC),
                              child: Column(
                                children: [
                                  PostSummaryCard(
                                    post: post,
                                    compact: true,
                                    showDivider: false,
                                    onTap: () async {
                                      await context.push('/post/${post.id}');
                                      if (context.mounted) {
                                        notifier.loadHotPosts();
                                      }
                                    },
                                  ),
                                  if (i < state.hotPosts.length - 1)
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFF0F4F8),
                                      indent: 18,
                                      endIndent: 18,
                                    ),
                                ],
                              ),
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

class _EmptyHotState extends StatelessWidget {
  final HotFilter filter;

  const _EmptyHotState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text(
            '${filter.label} HOT 게시글이 없어요',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '좋아요를 많이 받은 글이 여기에 모여요.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9AA7B2)),
          ),
        ],
      ),
    );
  }
}

/// 알림 배지 아이콘
class _HotNotificationButton extends ConsumerWidget {
  final Future<void> Function() onTap;

  const _HotNotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 26,
              color: Color(0xFF111111),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE05C7B),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
