import 'dart:async';

import 'package:flutter/material.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

OverlayEntry? _currentSnackBarEntry;
Timer? _currentSnackBarTimer;

void showAppSnackBar(String message, {Color? backgroundColor}) {
  final context = appScaffoldMessengerKey.currentState?.context;
  if (context == null) return;

  _showOverlaySnackBar(context, message, isError: backgroundColor != null);
}

void showContextSnackBar(BuildContext context, String message) {
  _showOverlaySnackBar(context, message);
}

void hideAppSnackBar() {
  _currentSnackBarTimer?.cancel();
  _currentSnackBarEntry?.remove();
  _currentSnackBarTimer = null;
  _currentSnackBarEntry = null;
}

void _showOverlaySnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  hideAppSnackBar();

  _currentSnackBarEntry = OverlayEntry(
    builder: (context) {
      final media = MediaQuery.of(context);
      final bottom =
          (media.viewInsets.bottom > 0
              ? media.viewInsets.bottom
              : media.padding.bottom) +
          14;

      return Positioned(
        left: 16,
        right: 16,
        bottom: bottom,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: _SnackBarToast(
              message: _friendlySnackBarMessage(message),
              isError: isError,
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(_currentSnackBarEntry!);
  _currentSnackBarTimer = Timer(const Duration(milliseconds: 2200), () {
    hideAppSnackBar();
  });
}

class _SnackBarToast extends StatelessWidget {
  final String message;
  final bool isError;

  const _SnackBarToast({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? const Color(0xFF311D24) : const Color(0xFF171A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFF5A2D3A) : const Color(0xFF2A303A),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Text(
          message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE7ECF2),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _friendlySnackBarMessage(String message) {
  var text = message.trim();
  if (text.isEmpty) return text;

  final replacements = <String, String>{
    '해주세요': '해 주세요',
    '할 수 없습니다': '할 수 없어요',
    '수 없습니다': '수 없어요',
    '없습니다': '없어요',
    '있습니다': '있어요',
    '않습니다': '않아요',
    '하였습니다': '했어요',
    '했습니다': '했어요',
    '되었습니다': '됐어요',
    '됩니다': '돼요',
    '가능합니다': '가능해요',
    '해야 합니다': '해야 해요',
  };

  for (final entry in replacements.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }

  return text.replaceAllMapped(RegExp(r'([가-힣A-Za-z0-9]+)입니다'), (match) {
    final word = match.group(1)!;
    final last = word.runes.last;
    if (last < 0xAC00 || last > 0xD7A3) return '$word이에요';
    final hasJongseong = (last - 0xAC00) % 28 != 0;
    return '$word${hasJongseong ? '이에요' : '예요'}';
  });
}
