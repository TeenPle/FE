import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../provider/login_provider.dart';
import '../provider/verification_reapply_provider.dart';

/// 학교 인증 반려 페이지
/// 반려 사유를 보여주고, 학생증 이미지를 다시 첨부해 재요청할 수 있음
class SchoolVerificationRejectedPage extends ConsumerStatefulWidget {
  const SchoolVerificationRejectedPage({super.key});

  @override
  ConsumerState<SchoolVerificationRejectedPage> createState() =>
      _SchoolVerificationRejectedPageState();
}

class _SchoolVerificationRejectedPageState
    extends ConsumerState<SchoolVerificationRejectedPage> {
  @override
  void initState() {
    super.initState();

    /// 화면 진입 시 반려 정보 조회
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginState = ref.read(loginProvider);

      ref.read(verificationReapplyProvider.notifier).fetchInfo(
        email: loginState.attemptedEmail,
        password: loginState.attemptedPassword,
      );
    });
  }

  /// 학생증 이미지 선택
  Future<void> _pickStudentCard() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null) {
      return;
    }

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    ref.read(verificationReapplyProvider.notifier).setSelectedFilePath(path);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final reapplyState = ref.watch(verificationReapplyProvider);
    final reapplyNotifier = ref.read(verificationReapplyProvider.notifier);

    final attemptedEmail = loginState.attemptedEmail;
    final attemptedPassword = loginState.attemptedPassword;

    final selectedFilePath = reapplyState.selectedFilePath;
    final selectedFileName = selectedFilePath.isEmpty
        ? ''
        : selectedFilePath.split(RegExp(r'[\\/]')).last;

    final canSubmit = reapplyState.info != null &&
        selectedFilePath.isNotEmpty &&
        !reapplyState.isSubmitLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: canSubmit
                ? () async {
              await reapplyNotifier.submit(
                email: attemptedEmail,
                password: attemptedPassword,
              );

              final latest = ref.read(verificationReapplyProvider);

              if (latest.isSubmitSuccess && context.mounted) {
                /// 재요청 성공 후 로그인 상태/재요청 상태 초기화
                ref.read(loginProvider.notifier).reset();
                reapplyNotifier.reset();

                /// 심사중 안내 페이지로 이동
                context.go(AppRoutes.schoolVerificationWaiting);
              }
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A67F2),
              disabledBackgroundColor: const Color(0xFFD7DEFF),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              reapplyState.isSubmitLoading ? '재요청 중...' : '다시 인증 요청하기',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: reapplyState.isInfoLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 뒤로가기
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              const SizedBox(height: 8),

              /// 상태 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  size: 30,
                  color: Color(0xFFFF7A45),
                ),
              ),

              const SizedBox(height: 24),

              /// 상태 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '학교 인증 반려',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF7A45),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 제목
              const Text(
                '학교 인증이 반려되었어요.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                  letterSpacing: -0.6,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 12),

              /// 설명
              const Text(
                '반려 사유를 확인한 뒤 학생증 사진을 다시 업로드해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF555555),
                ),
              ),

              const SizedBox(height: 24),

              /// 조회 에러
              if (reapplyState.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD8D8),
                    ),
                  ),
                  child: Text(
                    reapplyState.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      reapplyNotifier.fetchInfo(
                        email: attemptedEmail,
                        password: attemptedPassword,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF4A67F2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '다시 불러오기',
                      style: TextStyle(
                        color: Color(0xFF4A67F2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else if (reapplyState.info != null) ...[
                /// 학교 정보 카드
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
                      const Text(
                        '학교',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reapplyState.info!.schoolName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// 관리자 반려 사유 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFE1D1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '반려 사유',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF7A45),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        reapplyState.info!.adminComment.trim().isEmpty
                            ? '관리자 코멘트가 없습니다.'
                            : reapplyState.info!.adminComment,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 학생증 업로드 라벨
                const Text(
                  '학생증 이미지',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 8),

                /// 이미지 업로드 버튼
                GestureDetector(
                  onTap: _pickStudentCard,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedFilePath.isNotEmpty
                            ? const Color(0xFF4A67F2)
                            : const Color(0xFFE3E7EF),
                        width: selectedFilePath.isNotEmpty ? 1.3 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedFilePath.isNotEmpty
                              ? Icons.check_circle_rounded
                              : Icons.upload_rounded,
                          size: 20,
                          color: selectedFilePath.isNotEmpty
                              ? const Color(0xFF4A67F2)
                              : const Color(0xFF7A7A7A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFileName.isEmpty
                                ? '학생증 사진 다시 업로드하기'
                                : selectedFileName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selectedFileName.isEmpty
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: selectedFileName.isEmpty
                                  ? const Color(0xFF9A9A9A)
                                  : const Color(0xFF222222),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  '학생증 정보가 잘 보이는 사진을 올려주세요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),

                /// 선택한 이미지 미리보기
                if (selectedFilePath.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  const Text(
                    '미리보기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF666666),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE3E7EF),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(selectedFilePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              '이미지를 불러올 수 없어요.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    '선택한 이미지가 맞는지 확인해주세요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A67F2),
                    ),
                  ),
                ],

                if (reapplyState.submitErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    reapplyState.submitErrorMessage!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}