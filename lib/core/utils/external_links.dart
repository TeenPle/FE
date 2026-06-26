import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_snack_bar.dart';

Future<void> openExternalLink(
  BuildContext context,
  String url, {
  String fallbackMessage = '페이지를 열 수 없어요. 잠시 후 다시 시도해 주세요.',
}) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!context.mounted || opened) return;

  showContextSnackBar(context, fallbackMessage);
}
