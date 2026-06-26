import 'package:flutter/material.dart';
import 'package:teenple_frontend/core/theme/app_text_styles.dart';

import '../../../../core/theme/app_colors.dart';
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.dividerBlue),
          bottom: BorderSide(color: c.dividerBlue),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.poll_rounded,
                size: 19,
                color: Color(0xFF14A3F7),
              ),
              const SizedBox(width: 8),
              Text(
                '투표',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
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
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
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
    final c = context.colors;
    final fillRatio = showResult
        ? (option.percentage.clamp(0, 100) / 100.0)
        : 0.0;

    return InkWell(
      onTap: showResult || isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: c.tintBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: option.selectedByMe ? const Color(0xFF14A3F7) : c.border,
              ),
            ),
          ),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14A3F7).withValues(alpha: 0.16),
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
                        : c.iconSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (showResult) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${option.voteCount}명 (${option.percentage}%)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: c.textSecondary,
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
