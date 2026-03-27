import 'package:flutter/material.dart';
import '../../model/board_model.dart';

class BoardTabBar extends StatelessWidget {
  final List<BoardModel> boards;
  final int selectedBoardId;
  final ValueChanged<int> onBoardSelected;

  const BoardTabBar({
    super.key,
    required this.boards,
    required this.selectedBoardId,
    required this.onBoardSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: boards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final board = boards[index];
          final isSelected = board.id == selectedBoardId;

          return GestureDetector(
            onTap: () => onBoardSelected(board.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF2D6BFF), Color(0xFF19B5FF)],
                )
                    : null,
                color: isSelected ? null : const Color(0xFFE9EEF5),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF2D6BFF).withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: Text(
                  board.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}