import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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
  ConsumerState<AdminSchoolBoardsPage> createState() => _AdminSchoolBoardsPageState();
}

class _AdminSchoolBoardsPageState extends ConsumerState<AdminSchoolBoardsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminBoardListProvider(widget.schoolId).notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBoardListProvider(widget.schoolId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        title: Text(widget.schoolName, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminBoardListProvider(widget.schoolId).notifier)
                      .load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.boards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final board = state.boards[index];
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

class _BoardTile extends StatelessWidget {
  final AdminBoardModel board;
  final VoidCallback onTap;

  const _BoardTile({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRegion = board.scope == 'REGION';
    final color = isRegion ? const Color(0xFF7C6A46) : const Color(0xFF426C82);
    final bg = isRegion ? const Color(0xFFFFF7E8) : const Color(0xFFEAF3FB);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      board.scopeLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${board.postCount}개',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                board.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2933),
                ),
              ),
              if ((board.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  board.description!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
