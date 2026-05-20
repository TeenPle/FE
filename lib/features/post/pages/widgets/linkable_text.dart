import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:teenple_frontend/core/theme/app_text_styles.dart';
import 'package:flutter/services.dart';

/// URL을 감지해 탭 시 외부 이동 경고 다이얼로그를 띄우는 텍스트 위젯.
/// TapGestureRecognizer를 StatefulWidget에서 관리해 메모리 누수를 방지합니다.
class LinkableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
  });

  @override
  State<LinkableText> createState() => _LinkableTextState();
}

class _LinkableTextState extends State<LinkableText> {
  static final _urlRegex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(LinkableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final spans = <InlineSpan>[];
    final matches = _urlRegex.allMatches(widget.text);

    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, m.start)));
      }
      final url = m.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _showExternalLinkWarning(context, url);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: url,
          style:
              widget.linkStyle ??
              AppTextStyles.bodyMedium.copyWith(
                color: Color(0xFF14A3F7),
                decoration: TextDecoration.underline,
              ),
          recognizer: recognizer,
        ),
      );
      cursor = m.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(
        style:
            widget.style ??
            AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              height: 1.7,
              color: Color(0xFF2F3740),
            ),
        children: spans,
      ),
    );
  }
}

void _showExternalLinkWarning(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.open_in_new_rounded, size: 20, color: Color(0xFFE89C2F)),
          SizedBox(width: 8),
          Text('외부 사이트로 이동'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('아래 링크는 외부 사이트로 연결됩니다.\n유해한 콘텐츠가 포함될 수 있으니 주의하세요.'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              url,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: Color(0xFF5A8EA8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('링크가 클립보드에 복사됐어요.')));
            }
          },
          child: Text(
            '링크 복사',
            style: AppTextStyles.bodyMedium.copyWith(color: Color(0xFF14A3F7)),
          ),
        ),
      ],
    ),
  );
}
