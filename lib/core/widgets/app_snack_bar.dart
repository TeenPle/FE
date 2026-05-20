import 'package:flutter/material.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(String message, {Color? backgroundColor}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(_friendlySnackBarMessage(message)),
        backgroundColor: backgroundColor,
      ),
    );
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
