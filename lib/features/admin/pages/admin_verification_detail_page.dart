import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/base_url.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/verification_status_model.dart';
import '../provider/admin_verification_detail_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminVerificationDetailPage extends ConsumerStatefulWidget {
  final int requestId;

  const AdminVerificationDetailPage({super.key, required this.requestId});

  @override
  ConsumerState<AdminVerificationDetailPage> createState() =>
      _AdminVerificationDetailPageState();
}

class _AdminVerificationDetailPageState
    extends ConsumerState<AdminVerificationDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _commentFocusNode.removeListener(_onFocusChange);
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_commentFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}.$month.$day $hour:$minute';
  }

  String _buildImageUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return '';

    final baseUri = Uri.parse(apiBaseUrl);
    final baseOrigin = baseUri.hasPort
        ? '${baseUri.scheme}://${baseUri.host}:${baseUri.port}'
        : '${baseUri.scheme}://${baseUri.host}';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final imageUri = Uri.parse(url);
      final pointsToLocalhost =
          imageUri.host == 'localhost' || imageUri.host == '127.0.0.1';

      if (pointsToLocalhost && baseUri.host != imageUri.host) {
        final query = imageUri.hasQuery ? '?${imageUri.query}' : '';
        return '$baseOrigin${imageUri.path}$query';
      }

      return url;
    }

    return baseUri.resolve(url.startsWith('/') ? url : '/$url').toString();
  }

  Color _statusColor(VerificationStatusModel status) => switch (status) {
    VerificationStatusModel.pending => const Color(0xFF4A67F2),
    VerificationStatusModel.approved => const Color(0xFF16A34A),
    VerificationStatusModel.rejected => const Color(0xFFFF4D3A),
  };

  Color _statusBg(VerificationStatusModel status) => switch (status) {
    VerificationStatusModel.pending => const Color(0xFFEFF3FF),
    VerificationStatusModel.approved => const Color(0xFFECFDF3),
    VerificationStatusModel.rejected => const Color(0xFFFFF1F1),
  };

  IconData _statusIcon(VerificationStatusModel status) => switch (status) {
    VerificationStatusModel.pending => Icons.schedule_rounded,
    VerificationStatusModel.approved => Icons.check_circle_rounded,
    VerificationStatusModel.rejected => Icons.cancel_rounded,
  };

  String _statusLabel(VerificationStatusModel status) => switch (status) {
    VerificationStatusModel.pending => '심사 대기',
    VerificationStatusModel.approved => '승인 완료',
    VerificationStatusModel.rejected => '반려 완료',
  };

  String _statusHelper(VerificationStatusModel status) => switch (status) {
    VerificationStatusModel.pending => '현재 심사 대기 상태예요. 승인 또는 거절 처리를 진행할 수 있어요.',
    VerificationStatusModel.approved => '이미 승인된 요청이에요. 추가 처리는 할 수 없어요.',
    VerificationStatusModel.rejected => '이미 반려된 요청이에요. 추가 처리는 할 수 없어요.',
  };

  void _openImagePreview(String imageUrl) {
    if (imageUrl.isEmpty) {
      showAppSnackBar(
        '확대할 학생증 이미지가 없습니다.',
        backgroundColor: const Color(0xFFE05C7B),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _StudentCardImageViewer(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminVerificationDetailProvider(widget.requestId));
    final notifier = ref.read(
      adminVerificationDetailProvider(widget.requestId).notifier,
    );

    final detail = state.detail;
    final isPending = detail?.status == VerificationStatusModel.pending;
    final imageUrl = detail == null
        ? ''
        : _buildImageUrl(detail.requestImageUrl);
    final c = context.colors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: c.pageBg,
      appBar: AppBar(
        title: Text('인증 요청 상세'),
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      bottomNavigationBar: isPending
          ? AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.pageBg,
                  border: Border(top: BorderSide(color: c.borderSubtle)),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: AdminBottomActionFrame(
                    child: AdminResponsiveActions(
                      spacing: 12,
                      children: [
                        AdminActionButtonBox(
                          child: ElevatedButton.icon(
                            onPressed: state.isActionLoading
                                ? null
                                : () async {
                                    await notifier.approve(
                                      _commentController.text,
                                    );
                                    final latest = ref.read(
                                      adminVerificationDetailProvider(
                                        widget.requestId,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    if (latest.isActionSuccess) {
                                      showAppSnackBar('인증 요청을 승인했습니다.');
                                      Navigator.of(context).pop(true);
                                    } else if (latest.actionErrorMessage !=
                                        null) {
                                      showAppSnackBar(
                                        latest.actionErrorMessage!,
                                        backgroundColor: const Color(
                                          0xFFE05C7B,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              state.isActionLoading ? '처리 중...' : '승인',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1477F8),
                              disabledBackgroundColor: const Color(0xFFBFC8FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              textStyle: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        AdminActionButtonBox(
                          child: OutlinedButton.icon(
                            onPressed: state.isActionLoading
                                ? null
                                : () async {
                                    await notifier.reject(
                                      _commentController.text,
                                    );
                                    final latest = ref.read(
                                      adminVerificationDetailProvider(
                                        widget.requestId,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    if (latest.isActionSuccess) {
                                      showAppSnackBar('인증 요청을 거절했습니다.');
                                      Navigator.of(context).pop(true);
                                    } else if (latest.actionErrorMessage !=
                                        null) {
                                      showAppSnackBar(
                                        latest.actionErrorMessage!,
                                        backgroundColor: const Color(
                                          0xFFE05C7B,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              state.isActionLoading ? '처리 중...' : '거절',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE05C7B),
                              side: const BorderSide(color: Color(0xFFE05C7B)),
                              textStyle: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(
              child: Text(
                state.errorMessage ?? '상세 정보를 불러오지 못했습니다.',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            )
          : AdminContentFrame(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: AdminLayout.pagePadding(
                  context,
                  top: 8,
                  bottom: isPending ? 28 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPending) ...[
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () => _openImagePreview(imageUrl),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            height: (MediaQuery.of(context).size.height * 0.30)
                                .clamp(220.0, 360.0),
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: c.borderBlue),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0B2447,
                                  ).withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: imageUrl.isEmpty
                                        ? _ImagePlaceholder(
                                            c: c,
                                            message: '학생증 이미지가 없습니다.',
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    _ImagePlaceholder(
                                                      c: c,
                                                      message:
                                                          '이미지를 불러오지 못했습니다.',
                                                    ),
                                          ),
                                  ),
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.60,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.zoom_out_map_rounded,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '확대',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  height: 1,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _ReviewStatusPanel(
                      icon: _statusIcon(detail.status),
                      color: _statusColor(detail.status),
                      backgroundColor: _statusBg(detail.status),
                      title: _statusLabel(detail.status),
                      helper: _statusHelper(detail.status),
                    ),
                    const SizedBox(height: 12),

                    _ApplicantInfoPanel(
                      schoolName: detail.schoolName,
                      userName: detail.userName,
                      userEmail: detail.userEmail,
                      requestedAt: _formatDate(detail.requestedAt),
                      processedAt: detail.processedAt == null
                          ? null
                          : _formatDate(detail.processedAt),
                      adminComment: detail.adminComment,
                    ),

                    if (isPending) ...[
                      const SizedBox(height: 12),
                      _ReviewCommentPanel(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        errorMessage: state.actionErrorMessage,
                        onChanged: notifier.clearActionState,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors c;

  const _InfoRow({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: c.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: c.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStatusPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String helper;

  const _ReviewStatusPanel({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminDetailPanel(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  helper,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    height: 1.35,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantInfoPanel extends StatelessWidget {
  final String schoolName;
  final String userName;
  final String userEmail;
  final String requestedAt;
  final String? processedAt;
  final String? adminComment;

  const _ApplicantInfoPanel({
    required this.schoolName,
    required this.userName,
    required this.userEmail,
    required this.requestedAt,
    required this.processedAt,
    required this.adminComment,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _AdminDetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1477F8).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF1477F8),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  schoolName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _InfoRow(label: '이름', value: userName, c: c),
          _InfoRow(label: '이메일', value: userEmail, c: c),
          _InfoRow(label: '요청일', value: requestedAt, c: c),
          if (processedAt != null)
            _InfoRow(label: '처리일', value: processedAt!, c: c),
          if (adminComment != null && adminComment!.trim().isNotEmpty)
            _InfoRow(label: '코멘트', value: adminComment!, c: c),
        ],
      ),
    );
  }
}

class _ReviewCommentPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorMessage;
  final VoidCallback onChanged;

  const _ReviewCommentPanel({
    required this.controller,
    required this.focusNode,
    required this.errorMessage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _AdminDetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 19,
                color: Color(0xFF1477F8),
              ),
              const SizedBox(width: 7),
              Text(
                '심사 메모',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 4,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: '승인 코멘트 또는 거절 사유를 입력해주세요.',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: c.textHint,
              ),
              filled: true,
              fillColor: c.inputBg,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1477F8),
                  width: 1.2,
                ),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: const Color(0xFFE05C7B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminDetailPanel extends StatelessWidget {
  final Widget child;

  const _AdminDetailPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final AppColors c;
  final String message;

  const _ImagePlaceholder({required this.c, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: c.subtleBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: c.iconSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCardImageViewer extends StatelessWidget {
  final String imageUrl;

  const _StudentCardImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '이미지를 불러오지 못했습니다.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.58),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: '닫기',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
