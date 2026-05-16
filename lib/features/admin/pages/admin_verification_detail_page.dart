import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/verification_status_model.dart';
import '../provider/admin_verification_detail_provider.dart';

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

  static const String _androidBaseUrl = 'http://10.0.2.2:8080';
  static const String _defaultBaseUrl = 'http://localhost:8080';

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
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return url
            .replaceFirst('http://localhost:', 'http://10.0.2.2:')
            .replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:');
      }
      return url;
    }
    final baseUrl = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? _androidBaseUrl
        : _defaultBaseUrl;
    return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
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
      backgroundColor: c.pageBg,
      appBar: AppBar(
        title: const Text('인증 요청 상세'),
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      bottomNavigationBar: isPending
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isActionLoading
                            ? null
                            : () async {
                                await notifier.approve(_commentController.text);
                                final latest = ref.read(
                                  adminVerificationDetailProvider(
                                    widget.requestId,
                                  ),
                                );
                                if (!context.mounted) return;
                                if (latest.isActionSuccess) {
                                  showAppSnackBar('인증 요청을 승인했습니다.');
                                  Navigator.of(context).pop(true);
                                } else if (latest.actionErrorMessage != null) {
                                  showAppSnackBar(
                                    latest.actionErrorMessage!,
                                    backgroundColor: const Color(0xFFE05C7B),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A67F2),
                          disabledBackgroundColor: const Color(0xFFBFC8FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          state.isActionLoading ? '처리 중...' : '승인',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isActionLoading
                            ? null
                            : () async {
                                await notifier.reject(_commentController.text);
                                final latest = ref.read(
                                  adminVerificationDetailProvider(
                                    widget.requestId,
                                  ),
                                );
                                if (!context.mounted) return;
                                if (latest.isActionSuccess) {
                                  showAppSnackBar('인증 요청을 거절했습니다.');
                                  Navigator.of(context).pop(true);
                                } else if (latest.actionErrorMessage != null) {
                                  showAppSnackBar(
                                    latest.actionErrorMessage!,
                                    backgroundColor: const Color(0xFFE05C7B),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4D3A),
                          disabledBackgroundColor: const Color(0xFFFFC9C9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          state.isActionLoading ? '처리 중...' : '거절',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(
              child: Text(
                state.errorMessage ?? '상세 정보를 불러오지 못했습니다.',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPending) ...[
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.23,
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl.isEmpty
                          ? _ImagePlaceholder(c: c, message: '학생증 이미지가 없습니다.')
                          : InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    _ImagePlaceholder(
                                      c: c,
                                      message: '이미지를 불러오지 못했습니다.',
                                    ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 상태 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg(detail.status),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(detail.status),
                          size: 18,
                          color: _statusColor(detail.status),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusLabel(detail.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(detail.status),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _statusHelper(detail.status),
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 정보 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.schoolName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: '이름', value: detail.userName, c: c),
                        _InfoRow(label: '이메일', value: detail.userEmail, c: c),
                        _InfoRow(
                          label: '요청일',
                          value: _formatDate(detail.requestedAt),
                          c: c,
                        ),
                        if (detail.processedAt != null)
                          _InfoRow(
                            label: '처리일',
                            value: _formatDate(detail.processedAt),
                            c: c,
                          ),
                        if (detail.adminComment != null &&
                            detail.adminComment!.trim().isNotEmpty)
                          _InfoRow(
                            label: '코멘트',
                            value: detail.adminComment!,
                            c: c,
                          ),
                      ],
                    ),
                  ),

                  if (isPending) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLines: 4,
                      onChanged: (_) => notifier.clearActionState(),
                      decoration: InputDecoration(
                        hintText: '승인 코멘트 또는 거절 사유를 입력해주세요.',
                        hintStyle: TextStyle(fontSize: 12, color: c.textHint),
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
                            color: Color(0xFF4A67F2),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    if (state.actionErrorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.actionErrorMessage!,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ],
                ],
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
              style: TextStyle(fontSize: 11, color: c.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: c.textBody),
            ),
          ),
        ],
      ),
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
            Text(message, style: TextStyle(fontSize: 12, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}
