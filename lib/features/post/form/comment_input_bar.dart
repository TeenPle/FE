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
    if (text.isEmpty) return;

    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF3F9FF),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingToCommentId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '대댓글 작성 중',
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
                        Icons.close,
                        size: 18,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE7F0)),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: widget.anonymous,
                        onChanged: (value) {
                          widget.onAnonymousChanged(value ?? true);
                        },
                        activeColor: const Color(0xFF14A3F7),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text(
                        '익명',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14A3F7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Color(0xFF222222)),
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요.',
                        hintStyle: TextStyle(
                          color: Color(0xFF9AA7B2),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.isSubmitting ? null : _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.send_rounded,
                        color: Color(0xFF14A3F7),
                        size: 28,
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