import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_bottom_action_area.dart';
import '../../../app/routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/services/ios_image_upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../provider/signup_form_provider.dart';
import '../provider/signup_school_provider.dart';
import '../provider/signup_secret_store.dart';
import '../provider/signup_submit_provider.dart';

/// 회원가입 마지막 단계 - 재학 인증 사진 업로드 페이지
class SignupStudentCardPage extends ConsumerStatefulWidget {
  const SignupStudentCardPage({super.key});

  @override
  ConsumerState<SignupStudentCardPage> createState() =>
      _SignupStudentCardPageState();
}

class _SignupStudentCardPageState extends ConsumerState<SignupStudentCardPage> {
  Future<void> _pickStudentCard() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    NormalizedUploadImage? normalized;
    try {
      normalized = await IosImageUploadService.normalizeHeic(image.path);
    } catch (_) {
      showAppSnackBar('이미지를 변환하지 못했어요. 다른 사진을 선택해 주세요.');
      return;
    }
    final uploadPath = normalized?.path ?? image.path;
    if (!IosImageUploadService.hasAllowedExtension(uploadPath, const {
      'jpg',
      'jpeg',
      'png',
    })) {
      showAppSnackBar('JPG 또는 PNG 이미지만 업로드할 수 있어요.');
      return;
    }
    ref.read(signupFormProvider.notifier).updateStudentCardFilePath(uploadPath);

    /// 이전 회원가입 에러 상태 초기화
    ref.read(signupSubmitProvider.notifier).reset();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    /// 회원가입 전체 상태
    final signupFormState = ref.watch(signupFormProvider);

    /// 회원가입 요청 상태
    final submitState = ref.watch(signupSubmitProvider);

    /// 선택한 재학 인증 사진 파일 경로
    final studentCardFilePath = signupFormState.studentCardFilePath;

    /// 선택한 파일명
    final selectedFileName = studentCardFilePath.isEmpty
        ? ''
        : studentCardFilePath.split(RegExp(r'[\\/]')).last;

    /// 다음 버튼 활성화 조건
    final canProceed =
        studentCardFilePath.isNotEmpty &&
        SignupSecretStore.hasPassword &&
        !submitState.isLoading;

    return AuthStepLayout(
      bottom: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: canProceed
              ? () async {
                  /// 회원가입 요청
                  await ref
                      .read(signupSubmitProvider.notifier)
                      .submit(
                        signupFormState,
                        password: SignupSecretStore.password,
                      );

                  final latestSubmitState = ref.read(signupSubmitProvider);

                  /// 성공 시 로그인 화면 이동
                  if (latestSubmitState.isSuccess && context.mounted) {
                    final tokenStorage = ref.read(tokenStorageProvider);
                    await tokenStorage.saveRememberEmail(true);
                    await tokenStorage.saveSavedEmail(
                      signupFormState.email.trim(),
                    );

                    if (!context.mounted) return;

                    SignupSecretStore.clear();
                    ref.read(signupFormProvider.notifier).clear();
                    ref.read(signupSchoolProvider.notifier).clearSearch();
                    ref.read(signupSubmitProvider.notifier).reset();
                    context.go('${AppRoutes.login}?signup=success');
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A67F2),
            disabledBackgroundColor: isDark
                ? const Color(0xFF2D3460)
                : const Color(0xFFD7DEFF),
            foregroundColor: Colors.white,
            disabledForegroundColor: isDark ? Colors.white38 : Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            submitState.isLoading ? '가입 중...' : '완료',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 상단 뒤로가기 버튼
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            splashRadius: 22,
          ),

          SizedBox(height: 8),

          /// 단계 표시
          Text(
            '8/8',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textTertiary,
            ),
          ),

          SizedBox(height: 14),

          /// 페이지 성격 안내
          Text(
            '재학 인증',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A67F2),
            ),
          ),

          SizedBox(height: 8),

          /// 제목
          Text(
            '재학 인증에 사용할\n사진을 올려주세요',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.22,
              letterSpacing: -0.6,
              color: context.colors.textPrimary,
            ),
          ),

          SizedBox(height: 10),

          /// 보조 문구
          Text(
            '현재 학교에 다니고 있음을 확인할 수 있는 사진이면 괜찮아요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              height: 1.5,
              color: context.colors.textBody,
            ),
          ),

          SizedBox(height: 28),

          /// 재학 인증 사진 업로드 라벨
          Text(
            '재학 인증 사진',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.textMuted,
            ),
          ),

          SizedBox(height: 8),

          /// 업로드 버튼 영역
          GestureDetector(
            onTap: _pickStudentCard,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: studentCardFilePath.isNotEmpty
                    ? (isDark
                          ? const Color(0xFF1E2C46)
                          : const Color(0xFFF2F5FF))
                    : context.colors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: studentCardFilePath.isNotEmpty
                      ? const Color(0xFF4A67F2)
                      : context.colors.border,
                  width: studentCardFilePath.isNotEmpty ? 1.3 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    studentCardFilePath.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.upload_rounded,
                    size: 20,
                    color: studentCardFilePath.isNotEmpty
                        ? const Color(0xFF4A67F2)
                        : context.colors.iconSecondary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedFileName.isEmpty ? '사진 선택' : selectedFileName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: selectedFileName.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: selectedFileName.isEmpty
                            ? context.colors.textTertiary
                            : context.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 10),

          /// 안내 문구
          Text(
            '예) 학생증, 명찰, 학교에서 발급한 재학 확인 자료',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '이름과 학교 정보가 확인되면 불필요한 개인정보나 얼굴은 가려도 괜찮아요.',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: context.colors.textMuted,
            ),
          ),

          /// 선택한 이미지 미리보기
          if (studentCardFilePath.isNotEmpty) ...[
            SizedBox(height: 20),

            /// 미리보기 라벨
            Text(
              '미리보기',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.textMuted,
              ),
            ),

            SizedBox(height: 8),

            /// 이미지 미리보기 박스
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(studentCardFilePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        '이미지를 불러올 수 없어요.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 11,
                          color: context.colors.iconSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 10),

            /// 업로드 성공 안내
            Text(
              '선택한 이미지가 맞는지 확인해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: Color(0xFF4A67F2),
              ),
            ),
          ],

          /// 회원가입 에러 메시지
          if (submitState.errorMessage != null) ...[
            SizedBox(height: 8),
            Text(
              submitState.errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
