import 'package:flutter/material.dart';

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

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSubmitting) return;

    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF7FAFC),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingToCommentId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCFEAFF)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '답글 작성 중',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14A3F7),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6EDF3)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      widget.onAnonymousChanged(!widget.anonymous);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.anonymous
                            ? const Color(0xFFEAF7FF)
                            : const Color(0xFFF4F7FA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '익명',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: widget.anonymous
                              ? const Color(0xFF14A3F7)
                              : const Color(0xFF7D8790),
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
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                        hintStyle: TextStyle(
                          color: Color(0xFF9AA7B2),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.isSubmitting ? null : _submit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isSubmitting
                            ? const Color(0xFFD9EAF7)
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