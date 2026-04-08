import 'package:flutter/material.dart';
import '../models/board_model.dart';

class BoardTabBar extends StatelessWidget {
  final List<BoardModel> boards;
  final int? selectedBoardId;
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
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: boards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final board = boards[index];
          final isSelected = board.id == selectedBoardId;

          return GestureDetector(
            onTap: () => onBoardSelected(board.id),
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