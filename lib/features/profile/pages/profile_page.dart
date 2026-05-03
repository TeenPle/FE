import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../models/profile_model.dart';
import '../provider/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    ref.listen(profileProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(profileProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(profileProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '내 프로필',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF111111)),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : state.profile == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage ?? '프로필을 불러오지 못했습니다.',
                        style: const TextStyle(color: Color(0xFF7D8790)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(profileProvider.notifier).loadProfile(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      _ProfileHeaderCard(profile: state.profile!),
                      const SizedBox(height: 12),
                      _InfoSection(profile: state.profile!),
                      const SizedBox(height: 12),
                      _ActivitySection(),
                    ],
                  ),
                ),
    );
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

    final file = File(result.files.single.path!);
    if (!context.mounted) return;

    await ref.read(profileProvider.notifier).updateProfileImage(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(profileProvider).isSaving;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EDF3)),
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
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.nickname,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined,
                  size: 14, color: Color(0xFF9AA7B2)),
              const SizedBox(width: 4),
              Text(
                '${profile.schoolName} · ${profile.gradeLabel}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7D8790),
                ),
              ),
              if (profile.verified) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '인증됨',
                    style: TextStyle(
                      fontSize: 11,
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
                  : const Color(0xFFB0BEC5),
              side: BorderSide(
                color: profile.canChangeNickname
                    ? const Color(0xFF14A3F7)
                    : const Color(0xFFD0D8E4),
              ),
              disabledForegroundColor: const Color(0xFFB0BEC5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(
              profile.canChangeNickname
                  ? '닉네임 변경'
                  : '${profile.daysUntilNicknameChange}일 후 변경 가능',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 정보',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7D8790),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8)),
      ],
    );
  }
}

/// 활동 내역 섹션 — 내 글 / 내 댓글 / 공감한 글
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).profile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EDF3)),
      ),
      child: Column(
        children: [
          _ActivityTile(
            icon: Icons.article_outlined,
            label: '내가 쓴 글',
            count: profile?.myPostCount,
            onTap: () => context.push(AppRoutes.myPosts),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8),
              indent: 16, endIndent: 16),
          _ActivityTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: '내가 쓴 댓글',
            count: profile?.myCommentCount,
            onTap: () => context.push(AppRoutes.myComments),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8),
              indent: 16, endIndent: 16),
          _ActivityTile(
            icon: Icons.thumb_up_outlined,
            label: '내가 공감한 글',
            onTap: () => context.push(AppRoutes.myLikedPosts),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8),
              indent: 16, endIndent: 16),
          _ActivityTile(
            icon: Icons.bookmark_border_rounded,
            label: '내 북마크',
            onTap: () => context.push(AppRoutes.myBookmarks),
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
    final hasImage = profile.profileImageUrl.isNotEmpty &&
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
          placeholder: (_, __) => _defaultAvatar(),
          errorWidget: (_, __, ___) => _defaultAvatar(),
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
      child: const Icon(Icons.person_rounded, color: Color(0xFF8EA2B5), size: 44),
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF5A8EA8)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const Spacer(),
            if (count != null)
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14A3F7),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0BEC5), size: 22),
          ],
        ),
      ),
    );
  }
}
