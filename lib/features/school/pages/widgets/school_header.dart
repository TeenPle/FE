import 'package:flutter/material.dart';

class SchoolHeader extends StatelessWidget {
  final String schoolName;

  const SchoolHeader({
    super.key,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F9FF),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              color: const Color(0xFF9A9A9A),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                schoolName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const _CircleIcon(icon: Icons.account_circle_outlined),
            const SizedBox(width: 12),
            const _CircleIcon(icon: Icons.notifications_none),
            const SizedBox(width: 12),
            const _CircleIcon(icon: Icons.menu),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;

  const _CircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 28,
      color: Colors.black87,
    );
  }
}