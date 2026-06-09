import 'package:flutter/material.dart';
import 'package:teenple_frontend/core/theme/app_text_styles.dart';
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
  final FocusNode _focusNode = FocusNode();
  static const int _maxLength = 500;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousReplyId = oldWidget.replyingToCommentId;
    final currentReplyId = widget.replyingToCommentId;

    if (currentReplyId != null && currentReplyId != previousReplyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
      });
      return;
    }

    if (previousReplyId != null && currentReplyId == null) {
      _focusNode.unfocus();
    }
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
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF6EA8D8) : const Color(0xFF14A3F7);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    return ColoredBox(
      color: c.pageBg,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: keyboard > 0 ? keyboard : safeBottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.replyBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.borderBlue),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '답글 작성 중',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
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
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.anonymous
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 15,
                            color: widget.anonymous ? accent : c.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '익명',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: widget.anonymous ? accent : c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _isOverLimit
                            ? const Color(0xFFE05C5C)
                            : c.textBody,
                        fontSize: 13,
                        height: 1.25,
                      ),
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: c.textTertiary,
                          fontSize: 13,
                          height: 1.25,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: (widget.isSubmitting || _isOverLimit)
                        ? null
                        : _submit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (widget.isSubmitting || _isOverLimit)
                            ? c.tintBg
                            : const Color(0xFF14A3F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
