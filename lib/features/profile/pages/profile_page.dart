import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../../core/config/web_links.dart';
import '../../../core/services/ios_image_upload_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/external_links.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../features/auth/provider/login_provider.dart';
import '../../../features/chat/provider/chat_room_list_provider.dart';
import '../../../features/notification/provider/notification_setting_provider.dart';
import '../models/board_display_profile_model.dart';
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
    final c = context.colors;
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
      if (next.shouldGoToLogin && !(prev?.shouldGoToLogin ?? false)) {
        ref.read(authSessionProvider.notifier).clearTokens();
        ref.read(tokenStorageProvider).clearAll();
        context.go(AppRoutes.login);
      }
    });

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
          '내 정보',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : state.profile == null
          ? _ProfileLoadError(message: state.errorMessage)
          : RefreshIndicator(
              onRefresh: () => ref.read(profileProvider.notifier).loadProfile(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _ProfileHeaderCard(profile: state.profile!),
                  const SizedBox(height: 12),
                  _BoardProfilesSection(
                    profiles: state.boardProfiles,
                    verified: state.profile!.verified,
                    isLoading: state.isLoading,
                  ),
                  const SizedBox(height: 12),
                  _InfoSection(profile: state.profile!),
                  const SizedBox(height: 12),
                  const _ActivitySection(),
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
    default:
      return;
  }
}

class _ProfileLoadError extends ConsumerWidget {
  final String? message;

  const _ProfileLoadError({this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? '프로필을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

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
      showAppSnackBar('이미지를 처리하지 못했어요. 다른 사진을 선택해 주세요.');
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
    if (!context.mounted) return;
    await ref
        .read(profileProvider.notifier)
        .updateProfileImage(File(uploadPath));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isSaving = ref.watch(profileProvider).isSaving;
    final realName = profile.username.isNotEmpty
        ? profile.username
        : profile.email;

    return _ProfileSettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              GestureDetector(
                onTap: isSaving
                    ? null
                    : () => _pickAndUploadImage(context, ref),
                child: Stack(
                  children: [
                    _ProfileAvatar(profile: profile),
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
                realName,
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
                      fontSize: 12,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF14A3F7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardProfilesSection extends ConsumerStatefulWidget {
  final List<BoardDisplayProfileModel> profiles;
  final bool verified;
  final bool isLoading;

  const _BoardProfilesSection({
    required this.profiles,
    required this.verified,
    required this.isLoading,
  });

  @override
  ConsumerState<_BoardProfilesSection> createState() =>
      _BoardProfilesSectionState();
}

class _BoardProfilesSectionState extends ConsumerState<_BoardProfilesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profiles = widget.profiles;

    return _ProfileSettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 20,
                color: Color(0xFF14A3F7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 게시판별 프로필',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '게시글과 댓글에는 이 프로필이 표시됩니다.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        height: 1.35,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (profiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.tintBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${profiles.length}개',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14A3F7),
                    ),
                  ),
                ),
              IconButton(
                tooltip: '새로고침',
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                icon: Icon(Icons.refresh_rounded, color: c.iconSecondary),
              ),
            ],
          ),
        ),
        if (_expanded)
          _BoardProfilesExpandedBody(
            profiles: profiles,
            verified: widget.verified,
            isLoading: widget.isLoading,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: _BoardProfilesCollapsedBody(
              profiles: profiles,
              verified: widget.verified,
              isLoading: widget.isLoading,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(_expanded ? '접기' : '펼치기'),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardProfilesCollapsedBody extends StatelessWidget {
  final List<BoardDisplayProfileModel> profiles;
  final bool verified;
  final bool isLoading;

  const _BoardProfilesCollapsedBody({
    required this.profiles,
    required this.verified,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (!verified) {
      return const _BoardProfileMessage(
        icon: Icons.verified_user_outlined,
        title: '학교 인증 후 사용할 수 있어요.',
        subtitle: '인증 완료 후 게시판별 프로필 목록이 표시됩니다.',
      );
    }
    if (profiles.isEmpty) {
      return const _BoardProfileMessage(
        icon: Icons.info_outline_rounded,
        title: '아직 생성된 게시판 프로필이 없어요.',
        subtitle: '게시판에 처음 접근하거나 글을 작성하면 자동으로 생성됩니다.',
      );
    }

    final first = profiles.first;
    final hiddenCount = profiles.length - 1;
    return Row(
      children: [
        _BoardProfileAvatar(url: first.profileImageUrl, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.displayName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hiddenCount > 0
                    ? '${first.boardName} 외 $hiddenCount개 게시판'
                    : '${first.boardName} 게시판',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardProfilesExpandedBody extends StatelessWidget {
  final List<BoardDisplayProfileModel> profiles;
  final bool verified;
  final bool isLoading;

  const _BoardProfilesExpandedBody({
    required this.profiles,
    required this.verified,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!verified) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _BoardProfileMessage(
          icon: Icons.verified_user_outlined,
          title: '학교 인증 후 사용할 수 있어요.',
          subtitle: '인증을 완료하면 게시판별 프로필을 확인하고 관리할 수 있습니다.',
        ),
      );
    }
    if (profiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _BoardProfileMessage(
          icon: Icons.info_outline_rounded,
          title: '아직 생성된 게시판 프로필이 없어요.',
          subtitle: '게시판에 처음 접근하거나 글을 작성하면 자동으로 생성됩니다.',
        ),
      );
    }
    return Column(
      children: profiles.asMap().entries.map((entry) {
        return Column(
          children: [
            if (entry.key > 0) const _ProfileSettingsDivider(),
            _BoardProfileTile(profile: entry.value),
          ],
        );
      }).toList(),
    );
  }
}

class _BoardProfileTile extends ConsumerWidget {
  final BoardDisplayProfileModel profile;

  const _BoardProfileTile({required this.profile});

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    if (!profile.changeAvailable) {
      showAppSnackBar('${profile.remainingDays}일 후에 변경할 수 있어요.');
      return;
    }
    final result = await showModalBottomSheet<_BoardProfileEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BoardProfileEditSheet(profile: profile),
    );
    if (result == null || !context.mounted) return;
    await ref
        .read(profileProvider.notifier)
        .updateBoardDisplayProfile(
          boardId: profile.boardId,
          displayName: '',
          imageFile: result.imageFile,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final canChange = profile.changeAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _BoardProfileAvatar(url: profile.profileImageUrl, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.boardName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canChange ? '지금 변경 가능' : '${profile.remainingDays}일 후 변경 가능',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: canChange ? const Color(0xFF14A3F7) : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: ref.watch(profileProvider).isSaving
                ? null
                : () => _edit(context, ref),
            child: Text(canChange ? '변경' : '대기'),
          ),
        ],
      ),
    );
  }
}

class _BoardProfileEditSheet extends StatefulWidget {
  final BoardDisplayProfileModel profile;

  const _BoardProfileEditSheet({required this.profile});

  @override
  State<_BoardProfileEditSheet> createState() => _BoardProfileEditSheetState();
}

class _BoardProfileEditResult {
  final File? imageFile;

  const _BoardProfileEditResult({this.imageFile});
}

class _BoardProfileEditSheetState extends State<_BoardProfileEditSheet> {
  File? _imageFile;

  Future<void> _pickImage() async {
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
      showAppSnackBar('이미지를 처리하지 못했어요. 다른 사진을 선택해 주세요.');
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
    setState(() => _imageFile = File(uploadPath));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.profile.boardName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '저장하면 닉네임은 새 형용사와 4자리 숫자로 랜덤 발급됩니다. 프로필 사진도 함께 변경할 수 있어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              height: 1.4,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            _imageFile!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _BoardProfileAvatar(
                          url: widget.profile.profileImageUrl,
                          size: 76,
                        ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: Color(0xFF14A3F7),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '현재 닉네임: ${widget.profile.displayName}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '새 닉네임 예: 조용한틴플러#1842',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _BoardProfileEditResult(imageFile: _imageFile),
              ),
              child: const Text('랜덤 닉네임으로 변경 저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardProfileMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BoardProfileMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: c.iconSecondary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardProfileAvatar extends StatelessWidget {
  final String url;
  final double size;

  const _BoardProfileAvatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        url.isNotEmpty &&
        url != 'default_profile.png' &&
        url.startsWith('http');
    final radius = size * 0.28;
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _fallback(context, radius),
        ),
      );
    }
    return _fallback(context, radius);
  }

  Widget _fallback(BuildContext context, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.tintBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.person_rounded,
        color: context.colors.iconSecondary,
        size: size * 0.54,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final ProfileModel profile;

  const _InfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _ProfileSettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            '내 정보',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: c.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const _ProfileSettingsDivider(),
      ],
    );
  }
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).profile;
    return _ProfileSettingsCard(
      children: [
        _ProfileSettingsTile(
          icon: Icons.article_outlined,
          label: '내가 쓴 글',
          trailing: profile?.myPostCount.toString(),
          onTap: () => context.push(AppRoutes.myPosts),
        ),
        const _ProfileSettingsDivider(),
        _ProfileSettingsTile(
          icon: Icons.chat_bubble_outline_rounded,
          label: '내가 쓴 댓글',
          trailing: profile?.myCommentCount.toString(),
          onTap: () => context.push(AppRoutes.myComments),
        ),
        const _ProfileSettingsDivider(),
        _ProfileSettingsTile(
          icon: Icons.bookmark_border_rounded,
          label: '북마크',
          onTap: () => context.push(AppRoutes.myBookmarks),
        ),
        const _ProfileSettingsDivider(),
        _ProfileSettingsTile(
          icon: Icons.warning_amber_rounded,
          label: '내 경고 이력',
          onTap: () => context.push(AppRoutes.myWarnings),
        ),
      ],
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
              subtitle: '부적절 활동 신고: teenple.official@gmail.com',
              onTap: () => openExternalLink(context, teenpleSupportUrl),
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
              onTap: () => context.push(AppRoutes.accountDeleteConfirm),
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
    if (confirmed != true) return;
    final logoutFuture = ref.read(loginProvider.notifier).logout();
    if (context.mounted) {
      context.go(AppRoutes.login);
      showAppSnackBar('로그아웃되었어요.');
    }
    await logoutFuture;
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
                  fontSize: 14,
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
            fontSize: 12,
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
              fontSize: 14,
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
          onTap: () => openExternalLink(context, teenpleTermsUrl),
        ),
        const _ProfileSettingsDivider(),
        _ProfileSettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: '개인정보처리방침',
          onTap: () => openExternalLink(context, teenplePrivacyPolicyUrl),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.colors.textMuted,
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
      width: double.infinity,
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
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _ProfileSettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        height: 1.35,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14A3F7),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, color: c.iconSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileAvatar({required this.profile});

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
}
