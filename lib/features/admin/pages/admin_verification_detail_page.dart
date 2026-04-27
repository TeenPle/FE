import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verification_status_model.dart';
import '../provider/admin_verification_detail_provider.dart';

/// 관리자 학교 인증 요청 상세 페이지
class AdminVerificationDetailPage extends ConsumerStatefulWidget {
  final int requestId;

  const AdminVerificationDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<AdminVerificationDetailPage> createState() =>
      _AdminVerificationDetailPageState();
}

class _AdminVerificationDetailPageState
    extends ConsumerState<AdminVerificationDetailPage> {
  /// 관리자 코멘트 입력 컨트롤러
  final TextEditingController _commentController = TextEditingController();

  /// 안드로이드 에뮬레이터용 base url
  ///
  /// 지금은 로컬 테스트 대응용으로만 남겨두고,
  /// 나중에 S3 presigned URL을 내려주면 절대 URL이라 그대로 표시됨
  static const String _androidBaseUrl = 'http://10.0.2.2:8080';
  static const String _defaultBaseUrl = 'http://localhost:8080';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 날짜 포맷
  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '${value.year}.$month.$day $hour:$minute';
  }

  /// 이미지 URL 보정
  ///
  /// - 나중에 S3 presigned URL이 오면 그대로 사용
  /// - 현재 상대 경로가 오면 로컬 base url을 붙임
  String _buildImageUrl(String rawUrl) {
    final url = rawUrl.trim();

    if (url.isEmpty) {
      return '';
    }

    /// 이미 절대 URL이면 그대로 사용
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return url
            .replaceFirst('http://localhost:', 'http://10.0.2.2:')
            .replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:');
      }
      return url;
    }

    final baseUrl =
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? _androidBaseUrl
        : _defaultBaseUrl;

    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    return '$baseUrl/$url';
  }

  String _statusText(VerificationStatusModel status) {
    switch (status) {
      case VerificationStatusModel.pending:
        return '심사 대기';
      case VerificationStatusModel.approved:
        return '승인 완료';
      case VerificationStatusModel.rejected:
        return '반려 완료';
    }
  }

  Color _statusColor(VerificationStatusModel status) {
    switch (status) {
      case VerificationStatusModel.pending:
        return const Color(0xFF4A67F2);
      case VerificationStatusModel.approved:
        return const Color(0xFF16A34A);
      case VerificationStatusModel.rejected:
        return const Color(0xFFFF4D3A);
    }
  }

  Color _statusBackgroundColor(VerificationStatusModel status) {
    switch (status) {
      case VerificationStatusModel.pending:
        return const Color(0xFFEFF3FF);
      case VerificationStatusModel.approved:
        return const Color(0xFFECFDF3);
      case VerificationStatusModel.rejected:
        return const Color(0xFFFFF1F1);
    }
  }

  IconData _statusIcon(VerificationStatusModel status) {
    switch (status) {
      case VerificationStatusModel.pending:
        return Icons.schedule_rounded;
      case VerificationStatusModel.approved:
        return Icons.check_circle_rounded;
      case VerificationStatusModel.rejected:
        return Icons.cancel_rounded;
    }
  }

  String _statusHelperText(VerificationStatusModel status) {
    switch (status) {
      case VerificationStatusModel.pending:
        return '현재 심사 대기 상태예요. 승인 또는 거절 처리를 진행할 수 있어요.';
      case VerificationStatusModel.approved:
        return '이미 승인된 요청이에요. 추가 처리는 할 수 없어요.';
      case VerificationStatusModel.rejected:
        return '이미 반려된 요청이에요. 추가 처리는 할 수 없어요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminVerificationDetailProvider(widget.requestId));
    final notifier =
    ref.read(adminVerificationDetailProvider(widget.requestId).notifier);

    final detail = state.detail;

    final status = detail?.status;
    final isPending = status == VerificationStatusModel.pending;
    final imageUrl = detail == null ? '' : _buildImageUrl(detail.requestImageUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('인증 요청 상세'),
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
      ),
      bottomNavigationBar: isPending
          ? SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
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

                    if (latest.isActionSuccess && mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A67F2),
                    disabledBackgroundColor: const Color(0xFFBFC8FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    state.isActionLoading ? '처리 중...' : '승인',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
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

                    if (latest.isActionSuccess && mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D3A),
                    disabledBackgroundColor: const Color(0xFFFFC9C9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    state.isActionLoading ? '처리 중...' : '거절',
                    style: const TextStyle(
                      fontSize: 16,
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
          style: const TextStyle(
            fontSize: 14,
            color: Colors.red,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 학생증 이미지 영역 (심사 대기 중일 때만 표시)
            if (isPending) ...[
              Container(
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE3E7EF),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isEmpty
                    ? const _ImagePlaceholderCard(
                  message: '학생증 이미지가 없습니다.',
                )
                    : InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      return const _ImagePlaceholderCard(
                        message: '이미지를 불러오지 못했습니다.',
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            /// 상태 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusBackgroundColor(detail.status),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _statusIcon(detail.status),
                    size: 20,
                    color: _statusColor(detail.status),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusText(detail.status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(detail.status),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _statusHelperText(detail.status),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 기본 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE3E7EF),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.schoolName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '이름: ${detail.userName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이메일: ${detail.userEmail}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '요청일: ${_formatDate(detail.requestedAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '상태: ${detail.status.label}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF222222),
                    ),
                  ),
                  if (detail.processedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '처리일: ${_formatDate(detail.processedAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                  if (detail.adminComment != null &&
                      detail.adminComment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '관리자 코멘트: ${detail.adminComment}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 20),

              /// 관리자 코멘트 입력
              TextField(
                controller: _commentController,
                maxLines: 4,
                onChanged: (_) {
                  notifier.clearActionState();
                },
                decoration: InputDecoration(
                  hintText: '승인 코멘트 또는 거절 사유를 입력해주세요.',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE3E7EF),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE3E7EF),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A67F2),
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (state.actionErrorMessage != null)
                Text(
                  state.actionErrorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 이미지 실패/미연동 시 보여줄 placeholder
class _ImagePlaceholderCard extends StatelessWidget {
  final String message;

  const _ImagePlaceholderCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFD),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_not_supported_outlined,
                size: 36,
                color: Color(0xFF9AA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}