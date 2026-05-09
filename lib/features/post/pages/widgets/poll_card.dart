import 'package:flutter/material.dart';

import '../../models/poll_model.dart';

class PollCard extends StatelessWidget {
  final PollModel poll;
  final bool isSubmitting;
  final ValueChanged<int> onVote;

  const PollCard({
    super.key,
    required this.poll,
    required this.isSubmitting,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.poll_rounded, size: 19, color: Color(0xFF14A3F7)),
              SizedBox(width: 8),
              Text(
                '투표',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...poll.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PollOptionTile(
                option: option,
                showResult: poll.hasVoted,
                isSubmitting: isSubmitting,
                onTap: () => onVote(option.optionId),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '총 참여자 : ${poll.totalParticipants}명',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7D8790),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  final PollOptionModel option;
  final bool showResult;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _PollOptionTile({
    required this.option,
    required this.showResult,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fillRatio = showResult ? (option.percentage.clamp(0, 100) / 100.0) : 0.0;

    return InkWell(
      onTap: showResult || isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: option.selectedByMe
                    ? const Color(0xFF14A3F7)
                    : const Color(0xFFE1E9F0),
              ),
            ),
          ),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14A3F7).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    option.selectedByMe
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: option.selectedByMe
                        ? const Color(0xFF14A3F7)
                        : const Color(0xFF9AA7B2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  if (showResult) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${option.voteCount}명 (${option.percentage}%)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF52606D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
