import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/admin_content_model.dart';
import '../provider/admin_content_provider.dart';

class AdminSchoolBoardsPage extends ConsumerStatefulWidget {
  final int schoolId;
  final String schoolName;

  const AdminSchoolBoardsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  ConsumerState<AdminSchoolBoardsPage> createState() =>
      _AdminSchoolBoardsPageState();
}

class _AdminSchoolBoardsPageState extends ConsumerState<AdminSchoolBoardsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminBoardListProvider(widget.schoolId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBoardListProvider(widget.schoolId));
    final c = context.colors;
    final visibleBoards = state.boards
        .where((board) => board.scope != 'REGION')
        .toList(growable: false);

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          widget.schoolName,
          style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Text(state.error!, style: TextStyle(color: c.textMuted)),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(adminBoardListProvider(widget.schoolId).notifier)
                  .load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visibleBoards.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SchoolBoardsHeader(
                      schoolName: widget.schoolName,
                      boardCount: visibleBoards.length,
                    );
                  }
                  final board = visibleBoards[index - 1];
                  return _BoardTile(
                    board: board,
                    onTap: () => context.push(
                      AppRoutes.adminBoardPosts(board.id),
                      extra: {
                        'boardTitle': board.title,
                        'schoolName': widget.schoolName,
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _SchoolBoardsHeader extends StatelessWidget {
  final String schoolName;
  final int boardCount;

  const _SchoolBoardsHeader({
    required this.schoolName,
    required this.boardCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.tintBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.dashboard_customize_outlined,
              color: Color(0xFF1477F8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '게시판 모니터링',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _BoardCount(label: '전체', value: boardCount, c: c),
        ],
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  final AdminBoardModel board;
  final VoidCallback onTap;

  const _BoardTile({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const color = Color(0xFF426C82);
    final bg = c.tintBg;

    return Material(
      color: c.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: c.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      board.scopeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${board.postCount}개',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                board.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              if ((board.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  board.description!,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardCount extends StatelessWidget {
  final String label;
  final int value;
  final AppColors c;

  const _BoardCount({
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1477F8);
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: c.textMuted)),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
