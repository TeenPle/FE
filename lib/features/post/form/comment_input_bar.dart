import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../pages/widgets/crisis_banner.dart';

class CommentInputBar extends StatefulWidget {
  final bool anonymous;
  final bool isSubmitting;
  final int? replyingToCommentId;
  final ValueChanged<bool> onAnonymousChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancelReply;

  const CommentInputBar({
    super.key,
    required this.anonymous,
    required this.isSubmitting,
    required this.replyingToCommentId,
    required this.onAnonymousChanged,
    required this.onSubmit,
    required this.onCancelReply,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final TextEditingController _controller = TextEditingController();
  static const int _maxLength = 500;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _length => _controller.text.length;
  bool get _isOverLimit => _length > _maxLength;
  bool get _showCrisisBanner =>
      CrisisBanner.containsCrisisKeyword(_controller.text);

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSubmitting || _isOverLimit) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        color: c.pageBg,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_showCrisisBanner) ...[
              const CrisisBanner(),
              const SizedBox(height: 8),
            ],
            if (widget.replyingToCommentId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.replyBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.borderBlue),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '답글 작성 중',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14A3F7),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.borderStrong),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => widget.onAnonymousChanged(!widget.anonymous),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.anonymous ? c.tintBg : c.subtleBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '익명',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.anonymous
                              ? const Color(0xFF14A3F7)
                              : c.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(
                        color: _isOverLimit ? const Color(0xFFE05C5C) : c.textBody,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요',
                        hintStyle: TextStyle(
                          color: c.textTertiary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: (widget.isSubmitting || _isOverLimit) ? null : _submit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (widget.isSubmitting || _isOverLimit)
                            ? c.tintBg
                            : const Color(0xFF14A3F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
