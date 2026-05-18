import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/admin_content_model.dart';
import '../provider/admin_content_provider.dart';

class AdminPostDetailPage extends ConsumerStatefulWidget {
  final int postId;
  final int? focusCommentId;

  const AdminPostDetailPage({
    super.key,
    required this.postId,
    this.focusCommentId,
  });

  @override
  ConsumerState<AdminPostDetailPage> createState() =>
      _AdminPostDetailPageState();
}

class _AdminPostDetailPageState extends ConsumerState<AdminPostDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminPostDetailProvider(widget.postId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPostDetailProvider(widget.postId));
    final notifier = ref.read(adminPostDetailProvider(widget.postId).notifier);
    final c = context.colors;

    ref.listen(adminPostDetailProvider(widget.postId), (_, next) {
      if (!mounted) return;
      if (next.successMessage != null) {
        showAppSnackBar(next.successMessage!);
      }
      if (next.error != null && next.post != null) {
        showAppSnackBar(next.error!, backgroundColor: const Color(0xFFE05C7B));
      }
    });

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          '게시글 모더레이션',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.post == null
          ? Center(
              child: Text(
                state.error!,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          : state.post == null
          ? const SizedBox()
          : _PostDetailBody(
              post: state.post!,
              focusCommentId: widget.focusCommentId,
              isActing: state.isActing,
              onHidePost: notifier.hidePost,
              onRestorePost: notifier.restorePost,
              onHideComment: notifier.hideComment,
              onRestoreComment: notifier.restoreComment,
            ),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  final AdminPostDetailModel post;
  final int? focusCommentId;
  final bool isActing;
  final Future<void> Function(String reason) onHidePost;
  final Future<void> Function(String reason) onRestorePost;
  final Future<void> Function(int commentId, String reason) onHideComment;
  final Future<void> Function(int commentId, String reason) onRestoreComment;

  const _PostDetailBody({
    required this.post,
    this.focusCommentId,
    required this.isActing,
    required this.onHidePost,
    required this.onRestorePost,
    required this.onHideComment,
    required this.onRestoreComment,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PostSummaryHeader(post: post),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.article_outlined,
                title: '게시글 내용',
                trailing: Text(
                  _formatDate(post.createdAt),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: c.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: c.textBody,
                  height: 1.6,
                ),
              ),
              if (post.mediaList.isNotEmpty) ...[
                const SizedBox(height: 16),
                _MediaGrid(mediaList: post.mediaList),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    Icons.school_outlined,
                    post.schoolName ?? post.regionName ?? '학교/지역 없음',
                    c: c,
                  ),
                  _InfoChip(Icons.dashboard_outlined, post.boardTitle, c: c),
                  _InfoChip(Icons.person_outline, post.authorLabel, c: c),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                children: [
                  _Metric(
                    icon: Icons.visibility_outlined,
                    value: '조회 ${post.viewCount}',
                    c: c,
                  ),
                  _Metric(
                    icon: Icons.thumb_up_alt_outlined,
                    value: '공감 ${post.likeCount}',
                    c: c,
                  ),
                  _Metric(
                    icon: Icons.thumb_down_alt_outlined,
                    value: '비공감 ${post.dislikeCount}',
                    c: c,
                  ),
                  _Metric(
                    icon: Icons.mode_comment_outlined,
                    value: '댓글 ${post.commentCount}',
                    c: c,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                icon: Icons.admin_panel_settings_outlined,
                title: '운영 액션',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.adminUserHistory(post.authorUserId),
                    extra: {'nickname': post.authorLabel},
                  ),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: Text('작성자 이력'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF426C82),
                    side: const BorderSide(color: Color(0xFF426C82)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: post.postStatus == 'HIDDEN'
                    ? ElevatedButton.icon(
                        onPressed: isActing
                            ? null
                            : () => _confirmAction(
                                context,
                                title: '게시글 복구',
                                message: '숨김 처리된 게시글을 다시 노출할까요?',
                                confirmText: '복구',
                                onConfirm: onRestorePost,
                              ),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: Text('게시글 복구'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F7D46),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: isActing
                            ? null
                            : () => _confirmAction(
                                context,
                                title: '게시글 숨김',
                                message: '이 게시글을 사용자 화면에서 숨김 처리할까요?',
                                confirmText: '숨김 처리',
                                onConfirm: onHidePost,
                              ),
                        icon: const Icon(
                          Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        label: Text('게시글 숨김'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE05C7B),
                          side: const BorderSide(color: Color(0xFFE05C7B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.mode_comment_outlined,
                title: '댓글',
                trailing: Text(
                  '${post.comments.length}개',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (post.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '댓글이 없습니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.iconSecondary,
                    ),
                  ),
                )
              else
                ...post.comments.map(
                  (comment) => _CommentTile(
                    comment: comment,
                    highlighted: comment.commentId == focusCommentId,
                    isActing: isActing,
                    onHide: () => _confirmAction(
                      context,
                      title: '댓글 숨김',
                      message: '이 댓글을 사용자 화면에서 숨김 처리할까요?',
                      confirmText: '숨김 처리',
                      onConfirm: (reason) =>
                          onHideComment(comment.commentId, reason),
                    ),
                    onRestore: () => _confirmAction(
                      context,
                      title: '댓글 복구',
                      message: '숨김 처리된 댓글을 다시 노출할까요?',
                      confirmText: '복구',
                      onConfirm: (reason) =>
                          onRestoreComment(comment.commentId, reason),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Future<void> Function(String reason) onConfirm,
  }) {
    final reasonController = TextEditingController();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '처리 사유를 입력하세요.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: ctx.colors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                showAppSnackBar('처리 사유를 입력해주세요.');
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              confirmText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Color(0xFFE05C7B),
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      // 텍스트를 먼저 추출하고 controller를 dispose한 뒤 API를 호출한다.
      // onConfirm 호출 전에 dispose해야 메모리 누수 없이 안전하게 처리된다.
      final reason = reasonController.text.trim();
      reasonController.dispose();
      if (confirmed == true) onConfirm(reason);
    });
  }
}

class _PostSummaryHeader extends StatelessWidget {
  final AdminPostDetailModel post;

  const _PostSummaryHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final location = post.schoolName ?? post.regionName ?? '학교/지역 없음';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1477F8).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.tintBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF1477F8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '콘텐츠 모더레이션',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post.boardTitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(post.postStatus),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(Icons.school_outlined, location, c: c),
              _InfoChip(Icons.person_outline, post.authorLabel, c: c),
              _InfoChip(
                Icons.image_outlined,
                '첨부 ${post.mediaList.length}',
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  icon: Icons.visibility_outlined,
                  label: '조회',
                  value: post.viewCount,
                  c: c,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  icon: Icons.thumb_up_alt_outlined,
                  label: '공감',
                  value: post.likeCount,
                  c: c,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  icon: Icons.mode_comment_outlined,
                  label: '댓글',
                  value: post.commentCount,
                  c: c,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF1477F8)),
        const SizedBox(width: 7),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: c.textPrimary,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<AdminMediaModel> mediaList;

  const _MediaGrid({required this.mediaList});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mediaList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final media = mediaList[index];
        if (!media.isImage) {
          return Container(
            decoration: BoxDecoration(
              color: c.subtleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: c.iconSecondary,
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            media.url,
            fit: BoxFit.cover,
            // 이미지 로드 실패 시 깨진 이미지 아이콘으로 대체한다.
            errorBuilder: (context, error, stackTrace) => Container(
              color: c.subtleBg,
              child: Icon(Icons.broken_image_outlined, color: c.iconSecondary),
            ),
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final AdminCommentModel comment;
  final bool highlighted;
  final bool isActing;
  final VoidCallback onHide;
  final VoidCallback onRestore;

  const _CommentTile({
    required this.comment,
    this.highlighted = false,
    required this.isActing,
    required this.onHide,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: EdgeInsets.only(left: comment.depth > 0 ? 14 : 0, bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFFFFBEB)
            : comment.depth > 0
            ? c.replyBg
            : c.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? const Color(0xFFF59E0B) : c.border,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.authorLabel,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textBody,
                  ),
                ),
              ),
              _StatusBadge(comment.commentStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.content,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: c.textBody,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Metric(
                icon: Icons.thumb_up_alt_outlined,
                value: '${comment.likeCount}',
                c: c,
              ),
              const SizedBox(width: 10),
              _Metric(
                icon: Icons.thumb_down_alt_outlined,
                value: '${comment.dislikeCount}',
                c: c,
              ),
              const Spacer(),
              if (comment.commentStatus != 'DELETED')
                comment.commentStatus == 'HIDDEN'
                    ? TextButton.icon(
                        onPressed: isActing ? null : onRestore,
                        icon: const Icon(Icons.undo_rounded, size: 15),
                        label: Text('복구'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2F7D46),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: isActing ? null : onHide,
                        icon: const Icon(
                          Icons.visibility_off_outlined,
                          size: 15,
                        ),
                        label: Text('숨김'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE05C7B),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (status) {
      'ACTIVE' => const Color(0xFF2F7D46),
      'HIDDEN' => const Color(0xFFF59E0B),
      'DELETED' => c.textMuted,
      _ => c.textMuted,
    };
    final bg = switch (status) {
      'ACTIVE' => const Color(0xFFE8F5E9),
      'HIDDEN' => const Color(0xFFFFFBEB),
      _ => c.subtleBg,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(status),
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  String _label(String status) => switch (status) {
    'ACTIVE' => '노출 중',
    'HIDDEN' => '숨김',
    'DELETED' => '삭제됨',
    _ => status,
  };
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors c;

  const _InfoChip(this.icon, this.label, {required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.iconOnCard),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final AppColors c;

  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: c.subtleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: c.iconOnCard),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 10,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final AppColors c;

  const _Metric({required this.icon, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c.iconSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 11,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}
