import 'package:flutter/material.dart';
import '../models/board_model.dart';

class BoardTabBar extends StatelessWidget {
  final List<BoardModel> boards;
  final int? selectedBoardId;

  /// null → 전체 탭, boardId → 해당 게시판 탭
  final ValueChanged<int?> onTabSelected;

  const BoardTabBar({
    super.key,
    required this.boards,
    required this.selectedBoardId,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 전체 탭 + 개별 게시판 탭: 총 boards.length + 1개
    final itemCount = boards.length + 1;

    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          // index 0 = 전체 탭
          if (index == 0) {
            final isSelected = selectedBoardId == null;
            return GestureDetector(
              onTap: () => onTabSelected(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF14A3F7) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '전체',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF4B4B4B),
                  ),
                ),
              ),
            );
          }

          final board = boards[index - 1];
          final isSelected = board.id == selectedBoardId;

          return GestureDetector(
            onTap: () => onTabSelected(board.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF14A3F7) : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                board.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF4B4B4B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
