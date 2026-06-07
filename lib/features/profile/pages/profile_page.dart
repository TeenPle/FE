import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../../core/services/ios_image_upload_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../features/auth/provider/login_provider.dart';
import '../../../features/chat/provider/chat_room_list_provider.dart';
import '../../../features/notification/provider/notification_setting_provider.dart';
import '../models/profile_model.dart';
import '../provider/profile_provider.dart';
import '../widgets/block_summary_tile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
      ref.read(chatRoomListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final chatUnreadCount = ref
        .watch(chatRoomListProvider)
        .rooms
        .fold(0, (sum, room) => sum + room.unreadCount);

    ref.listen(profileProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        showAppSnackBar(
          next.errorMessage!,
          backgroundColor: const Color(0xFFE05C7B),
        );
        ref.read(profileProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        showAppSnackBar(next.successMessage!);
        ref.read(profileProvider.notifier).clearMessages();
      }
      // shouldGoToLogin이 false → true로 전환될 때만 반응한다.
      // 이전 상태에서 이미 true였던 경우(복구 후 재진입 등)는 무시해야 오염된 상태로
      // 정상 세션이 지워지는 것을 막을 수 있다.
      if (next.shouldGoToLogin && !(prev?.shouldGoToLogin ?? false)) {
        ref.read(authSessionProvider.notifier).clearTokens();
        ref.read(tokenStorageProvider).clearAll();
        context.go(AppRoutes.login);
      }
    });

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        chatUnreadCount: chatUnreadCount,
        onTap: (index) => _goMainTab(context, index),
      ),
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '내 프로필',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : state.profile == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage ?? '프로필을 불러오지 못했어요.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(profileProvider.notifier).loadProfile(),
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(profileProvider.notifier).loadProfile(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _ProfileHeaderCard(profile: state.profile!),
                  const SizedBox(height: 12),
                  _InfoSection(profile: state.profile!),
                  const SizedBox(height: 12),
                  _ActivitySection(),
                  const SizedBox(height: 12),
                  const _SettingsSection(),
                ],
              ),
            ),
    );
  }
}

void _goMainTab(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutes.school);
      return;
    case 1:
      context.go(AppRoutes.chat);
      return;
    case 2:
      context.go(AppRoutes.meal);
      return;
    case 3:
      context.go(AppRoutes.timetable);
      return;
    case 4:
      return;
  }
}

/// 상단 — 아바타 + 닉네임 + 학교
class _ProfileHeaderCard extends ConsumerWidget {
  final ProfileModel profile;

  const _ProfileHeaderCard({required this.profile});

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final originalPath = result.files.single.path!;
    NormalizedUploadImage? normalized;
    try {
      normalized = await IosImageUploadService.normalizeHeic(originalPath);
    } catch (_) {
      showAppSnackBar('이미지를 변환하지 못했어요. 다른 사진을 선택해 주세요.');
      return;
    }
    final uploadPath = normalized?.path ?? originalPath;
    if (!IosImageUploadService.hasAllowedExtension(uploadPath, const {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    })) {
      showAppSnackBar('JPG, PNG, GIF, WEBP 이미지만 업로드할 수 있어요.');
      return;
    }
    final file = File(uploadPath);
    if (!context.mounted) return;

    await ref.read(profileProvider.notifier).updateProfileImage(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(profileProvider).isSaving;

    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isSaving ? null : () => _pickAndUploadImage(context, ref),
            child: Stack(
              children: [
                _AvatarWidget(profile: profile),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14A3F7),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.cardBg, width: 2),
                    ),
                    child: isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.nickname,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 14, color: c.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${profile.schoolName} · ${profile.gradeLabel}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  color: c.textMuted,
                ),
              ),
              if (profile.verified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.tintBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '인증됨',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14A3F7),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: profile.canChangeNickname
                ? () => context.push(AppRoutes.editNickname)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: profile.canChangeNickname
                  ? const Color(0xFF14A3F7)
                  : c.iconSecondary,
              side: BorderSide(
                color: profile.canChangeNickname
                    ? const Color(0xFF14A3F7)
                    : c.border,
              ),
              disabledForegroundColor: c.iconSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(
              profile.canChangeNickname
                  ? '닉네임 변경'
                  : '${profile.daysUntilNicknameChange}일 후 변경 가능',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 내 정보 섹션
class _InfoSection extends StatelessWidget {
  final ProfileModel profile;

  const _InfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 정보',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: '이메일', value: profile.email),
          _InfoRow(label: '성별', value: profile.genderLabel),
          _InfoRow(label: '학년', value: profile.gradeLabel),
          _InfoRow(
            label: '학교 인증',
            value: profile.verified ? '인증 완료' : '미인증',
            valueColor: profile.verified
                ? const Color(0xFF14A3F7)
                : const Color(0xFFE05C5C),
          ),
          _InfoRow(
            label: '전화번호 인증',
            value: profile.phoneVerified ? '인증 완료' : '미인증',
            valueColor: profile.phoneVerified
                ? const Color(0xFF14A3F7)
                : const Color(0xFFE05C5C),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: c.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: c.borderSubtle),
      ],
    );
  }
}

/// 활동 내역 섹션 — 내 글 / 내 댓글 / 공감한 글
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(profileProvider).profile;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        children: [
          _ActivityTile(
            icon: Icons.article_outlined,
            label: '내가 쓴 글',
            count: profile?.myPostCount,
            onTap: () => context.push(AppRoutes.myPosts),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: c.borderSubtle,
            indent: 16,
            endIndent: 16,
          ),
          _ActivityTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: '내가 쓴 댓글',
            count: profile?.myCommentCount,
            onTap: () => context.push(AppRoutes.myComments),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: c.borderSubtle,
            indent: 16,
            endIndent: 16,
          ),
          _ActivityTile(
            icon: Icons.bookmark_border_rounded,
            label: '내 북마크',
            onTap: () => context.push(AppRoutes.myBookmarks),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: c.borderSubtle,
            indent: 16,
            endIndent: 16,
          ),
          _ActivityTile(
            icon: Icons.warning_amber_rounded,
            label: '내 경고 이력',
            onTap: () => context.push(AppRoutes.myWarnings),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final ProfileModel profile;
  const _AvatarWidget({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        profile.profileImageUrl.isNotEmpty &&
        profile.profileImageUrl != 'default_profile.png' &&
        profile.profileImageUrl.startsWith('http');

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: CachedNetworkImage(
          imageUrl: profile.profileImageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (_, _) => _defaultAvatar(),
          errorWidget: (_, _, _) => _defaultAvatar(),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FB),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8EA2B5),
        size: 44,
      ),
    );
  }

  // Avatar uses fixed colors intentionally — acts as a brand accent
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;
  final bool isLast;

  const _ActivityTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF14A3F7)),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const Spacer(),
            if (count != null)
              Text(
                '$count',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14A3F7),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.iconSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProfileSectionHeader(label: '계정 관리'),
        _ProfileSettingsCard(
          children: [
            _ProfileSettingsTile(
              icon: Icons.lock_outline_rounded,
              label: '비밀번호 변경',
              onTap: () => context.push(AppRoutes.editPassword),
            ),
            const _ProfileSettingsDivider(),
            const BlockSummaryTile(),
            const _ProfileSettingsDivider(),
            _ProfileSettingsTile(
              icon: Icons.gavel_rounded,
              label: '제재 이력',
              onTap: () => context.push(AppRoutes.myPenalties),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ProfileSectionHeader(label: '화면'),
        const _ProfileThemeCard(),
        const SizedBox(height: 18),
        const _ProfileSectionHeader(label: 'D-Day'),
        _ProfileSettingsCard(
          children: [
            _ProfileSettingsTile(
              icon: Icons.event_available_outlined,
              label: 'D-Day 관리',
              onTap: () => context.push(AppRoutes.ddaySettings),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ProfileSectionHeader(label: '알림 설정'),
        const _ProfileNotificationSettingsCard(),
        const SizedBox(height: 18),
        const _ProfileSectionHeader(label: '앱 정보'),
        const _ProfileAppInfoCard(),
        const SizedBox(height: 18),
        const _ProfileSectionHeader(label: '기타'),
        _ProfileSettingsCard(
          children: [
            _ProfileSettingsTile(
              icon: Icons.support_agent_rounded,
              label: '문의하기',
              onTap: () => context.push(AppRoutes.inquiries),
            ),
            const _ProfileSettingsDivider(),
            _ProfileSettingsTile(
              icon: Icons.logout_rounded,
              label: '로그아웃',
              onTap: () => _confirmLogout(context, ref),
            ),
            const _ProfileSettingsDivider(),
            _ProfileSettingsTile(
              icon: Icons.person_remove_outlined,
              label: '회원 탈퇴',
              labelColor: const Color(0xFFE05C5C),
              iconColor: const Color(0xFFE05C5C),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'),
        content: Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 로그아웃 정리 작업은 네트워크 요청이 포함될 수 있으므로, 사용자는
      // 즉시 로그인 화면으로 보내고 로컬/서버 세션 정리는 이어서 완료한다.
      final logoutFuture = ref.read(loginProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutes.login);
        showAppSnackBar('로그아웃되었습니다.');
      }
      await logoutFuture;
    }
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    context.push(AppRoutes.accountDeleteConfirm);
  }
}

class _ProfileThemeCard extends ConsumerWidget {
  const _ProfileThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return _ProfileSettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.dark_mode_outlined,
                size: 20,
                color: Color(0xFF14A3F7),
              ),
              const SizedBox(width: 14),
              Text(
                '테마',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              _ProfileThemeSegment(
                label: '라이트',
                selected: mode == ThemeMode.light,
                onTap: () => notifier.setMode(ThemeMode.light),
              ),
              const SizedBox(width: 6),
              _ProfileThemeSegment(
                label: '다크',
                selected: mode == ThemeMode.dark,
                onTap: () => notifier.setMode(ThemeMode.dark),
              ),
              const SizedBox(width: 6),
              _ProfileThemeSegment(
                label: '자동',
                selected: mode == ThemeMode.system,
                onTap: () => notifier.setMode(ThemeMode.system),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileThemeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileThemeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF14A3F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF14A3F7) : c.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : c.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _ProfileNotificationSettingsCard extends ConsumerWidget {
  const _ProfileNotificationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingAsync = ref.watch(notificationSettingProvider);

    return settingAsync.when(
      loading: () => const _ProfileSettingsCard(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      ),
      error: (_, _) => const _ProfileSettingsCard(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text('알림 설정을 불러올 수 없습니다.'),
          ),
        ],
      ),
      data: (setting) => _ProfileSettingsCard(
        children: [
          _ProfileNotificationToggleTile(
            icon: Icons.notifications_outlined,
            label: '전체 알림',
            value: setting.allowPush,
            onChanged: (v) => _update(context, ref, _pushPatch(v)),
          ),
          const _ProfileSettingsDivider(),
          _ProfileNotificationToggleTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: '댓글 알림',
            value: setting.allowCommentNotification,
            enabled: setting.allowPush,
            onChanged: (v) =>
                _update(context, ref, {'allowCommentNotification': v}),
          ),
          const _ProfileSettingsDivider(),
          _ProfileNotificationToggleTile(
            icon: Icons.reply_rounded,
            label: '답글 알림',
            value: setting.allowReplyNotification,
            enabled: setting.allowPush,
            onChanged: (v) =>
                _update(context, ref, {'allowReplyNotification': v}),
          ),
          const _ProfileSettingsDivider(),
          _ProfileNotificationToggleTile(
            icon: Icons.thumb_up_outlined,
            label: '좋아요 알림',
            value: setting.allowLikeNotification,
            enabled: setting.allowPush,
            onChanged: (v) =>
                _update(context, ref, {'allowLikeNotification': v}),
          ),
          const _ProfileSettingsDivider(),
          _ProfileNotificationToggleTile(
            icon: Icons.forum_outlined,
            label: '채팅 알림',
            value: setting.allowChatNotification,
            enabled: setting.allowPush,
            onChanged: (v) =>
                _update(context, ref, {'allowChatNotification': v}),
          ),
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> patch,
  ) {
    ref
        .read(notificationSettingProvider.notifier)
        .updateSetting(patch)
        .catchError((_) {
          showAppSnackBar(
            '설정 저장에 실패했어요.',
            backgroundColor: const Color(0xFFE05C7B),
          );
        });
  }

  Map<String, dynamic> _pushPatch(bool allowPush) {
    if (!allowPush) return {'allowPush': false};
    return {
      'allowPush': true,
      'allowCommentNotification': true,
      'allowReplyNotification': true,
      'allowLikeNotification': true,
      'allowChatNotification': true,
    };
  }
}

class _ProfileNotificationToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ProfileNotificationToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = enabled && value;
    final color = enabled ? c.textPrimary : c.iconSecondary;
    final iconColor = enabled ? const Color(0xFF14A3F7) : c.iconSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: active,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: const Color(0xFF14A3F7),
          ),
        ],
      ),
    );
  }
}

class _ProfileAppInfoCard extends StatefulWidget {
  const _ProfileAppInfoCard();

  @override
  State<_ProfileAppInfoCard> createState() => _ProfileAppInfoCardState();
}

class _ProfileAppInfoCardState extends State<_ProfileAppInfoCard> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSettingsCard(
      children: [
        _ProfileInfoTile(label: '앱 버전', trailing: _version),
        const _ProfileSettingsDivider(),
        _ProfileSettingsTile(
          icon: Icons.description_outlined,
          label: '이용약관',
          onTap: () => context.push(AppRoutes.terms),
        ),
        const _ProfileSettingsDivider(),
        _ProfileSettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: '개인정보처리방침',
          onTap: () => context.push(AppRoutes.privacyPolicy),
        ),
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final String label;
  final String trailing;

  const _ProfileInfoTile({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Color(0xFF14A3F7),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final String label;
  const _ProfileSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c.textMuted,
        ),
      ),
    );
  }
}

class _ProfileSettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileSettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileSettingsDivider extends StatelessWidget {
  const _ProfileSettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.borderSubtle,
      indent: 52,
    );
  }
}

class _ProfileSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _ProfileSettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = labelColor ?? c.textPrimary;
    final iColor = iconColor ?? const Color(0xFF14A3F7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: c.iconSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
