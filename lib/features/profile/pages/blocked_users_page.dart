import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/block_provider.dart';

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(blockedUsersProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '차단 목록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                '차단한 유저가 없습니다.',
                style: TextStyle(fontSize: 15, color: Color(0xFF9AA7B2)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6EDF3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // 프로필 아바타
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFCEE8F5),
                      backgroundImage: (user.profileImageUrl != null &&
                              user.profileImageUrl!.isNotEmpty &&
                              user.profileImageUrl!.startsWith('http'))
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: (user.profileImageUrl == null ||
                              user.profileImageUrl!.isEmpty ||
                              !user.profileImageUrl!.startsWith('http'))
                          ? const Icon(Icons.person_rounded,
                              color: Color(0xFF3A9BD5), size: 22)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // 닉네임
                    Expanded(
                      child: Text(
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    // 차단 해제 버튼
                    TextButton(
                      onPressed: () => _confirmUnblock(context, ref, user.userId, user.nickname),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF9AA7B2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFD0D8E4)),
                        ),
                      ),
                      child: const Text('차단 해제', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmUnblock(
      BuildContext context, WidgetRef ref, int userId, String nickname) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('차단 해제'),
        content: Text('$nickname 님의 차단을 해제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('해제')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(blockedUsersProvider.notifier).unblock(userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('차단이 해제되었습니다.')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('차단 해제에 실패했습니다.')));
        }
      }
    }
  }
}
