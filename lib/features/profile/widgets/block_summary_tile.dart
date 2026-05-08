import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/block_provider.dart';

class BlockSummaryTile extends ConsumerWidget {
  const BlockSummaryTile({
    super.key,
    this.horizontalPadding = 16,
    this.verticalPadding = 14,
  });

  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(blockSummaryProvider);
    final count = summary.valueOrNull ?? 0;
    final isLoading = summary.isLoading && !summary.hasValue;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, size: 20, color: Color(0xFF14A3F7)),
          const SizedBox(width: 14),
          const Text(
            '차단한 사용자',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            Text(
              '$count명',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7D8790),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: count == 0
                  ? null
                  : () => _confirmUnblockAll(context, ref),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: const Color(0xFFE05C5C),
                disabledForegroundColor: const Color(0xFFB0BEC5),
              ),
              child: const Text(
                '전체 해제',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmUnblockAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('차단 전체 해제'),
        content: const Text('차단한 모든 사용자의 차단을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE05C5C),
            ),
            child: const Text('전체 해제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(blockSummaryProvider.notifier).unblockAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단이 모두 해제되었습니다.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단 해제에 실패했습니다.')),
        );
      }
    }
  }
}
