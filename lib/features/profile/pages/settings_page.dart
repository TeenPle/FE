import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../../features/auth/provider/login_provider.dart';
import '../../../features/notification/provider/notification_setting_provider.dart';
import '../provider/profile_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileProvider, (prev, next) {
      if (next.shouldGoToLogin) {
        ref.read(authSessionProvider.notifier).clearTokens();
        ref.read(tokenStorageProvider).clearAll();
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 계정 관리
          _SectionHeader(label: '계정 관리'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: '비밀번호 변경',
                onTap: () => context.push(AppRoutes.editPassword),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.gavel_rounded,
                label: '제재 이력',
                onTap: () => context.push(AppRoutes.myPenalties),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 알림 설정
          _SectionHeader(label: '알림 설정'),
          const SizedBox(height: 8),
          const _NotificationSettingsCard(),

          const SizedBox(height: 20),

          // 앱 정보
          _SectionHeader(label: '앱 정보'),
          const SizedBox(height: 8),
          const _AppInfoCard(),

          const SizedBox(height: 20),

          // 기타
          _SectionHeader(label: '기타'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: '로그아웃',
                onTap: () => _confirmLogout(context, ref),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.person_remove_outlined,
                label: '회원 탈퇴',
                labelColor: const Color(0xFFE05C5C),
                iconColor: const Color(0xFFE05C5C),
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(loginProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C5C)),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(profileProvider.notifier).deleteAccount();
    }
  }
}

// ────────────────────────────────────────────
// 알림 설정 카드
// ────────────────────────────────────────────

class _NotificationSettingsCard extends ConsumerWidget {
  const _NotificationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingAsync = ref.watch(notificationSettingProvider);

    return settingAsync.when(
      loading: () => const _SettingsCard(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      ),
      error: (_, __) => const _SettingsCard(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text('알림 설정을 불러올 수 없습니다.'),
          ),
        ],
      ),
      data: (setting) => _SettingsCard(
        children: [
          _NotificationToggleTile(
            icon: Icons.notifications_outlined,
            label: '전체 알림',
            value: setting.allowPush,
            onChanged: (v) => _update(context, ref, {'allowPush': v}),
          ),
          const _Divider(),
          _NotificationToggleTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: '댓글 알림',
            value: setting.allowCommentNotification,
            enabled: setting.allowPush,
            onChanged: (v) => _update(context, ref, {'allowCommentNotification': v}),
          ),
          const _Divider(),
          _NotificationToggleTile(
            icon: Icons.reply_rounded,
            label: '답글 알림',
            value: setting.allowReplyNotification,
            enabled: setting.allowPush,
            onChanged: (v) => _update(context, ref, {'allowReplyNotification': v}),
          ),
          const _Divider(),
          _NotificationToggleTile(
            icon: Icons.thumb_up_outlined,
            label: '좋아요 알림',
            value: setting.allowLikeNotification,
            enabled: setting.allowPush,
            onChanged: (v) => _update(context, ref, {'allowLikeNotification': v}),
          ),
          const _Divider(),
          _NotificationToggleTile(
            icon: Icons.forum_outlined,
            label: '채팅 알림',
            value: setting.allowChatNotification,
            enabled: setting.allowPush,
            onChanged: (v) => _update(context, ref, {'allowChatNotification': v}),
          ),
        ],
      ),
    );
  }

  void _update(BuildContext context, WidgetRef ref, Map<String, dynamic> patch) {
    ref.read(notificationSettingProvider.notifier).updateSetting(patch).catchError((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정 저장에 실패했습니다.')),
        );
      }
    });
  }
}

class _NotificationToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && value;
    final color = enabled ? const Color(0xFF111111) : const Color(0xFFB0BEC5);
    final iconColor = enabled ? const Color(0xFF5A8EA8) : const Color(0xFFB0BEC5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: active,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF5A8EA8),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────
// 앱 정보 카드
// ────────────────────────────────────────────

class _AppInfoCard extends StatefulWidget {
  const _AppInfoCard();

  @override
  State<_AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<_AppInfoCard> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페이지를 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        _InfoTile(label: '앱 버전', trailing: _version),
        const _Divider(),
        _SettingsTile(
          icon: Icons.description_outlined,
          label: '이용약관',
          onTap: () => _launchUrl('https://teenple.com/terms'),
        ),
        const _Divider(),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: '개인정보처리방침',
          onTap: () => _launchUrl('https://teenple.com/privacy'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String trailing;

  const _InfoTile({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF5A8EA8)),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9AA7B2),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────
// 공통 위젯
// ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9AA7B2),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8), indent: 52);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? const Color(0xFF111111);
    final iColor = iconColor ?? const Color(0xFF5A8EA8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BEC5), size: 22),
          ],
        ),
      ),
    );
  }
}
