import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_bottom_action_area.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/signup_form_provider.dart';

/// 회원가입 2단계 - 학년 선택 페이지
class SignupStudentInfoPage extends ConsumerWidget {
  const SignupStudentInfoPage({super.key});

  /// 학년 선택 바텀시트를 띄우는 함수
  void _showGradeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        /// 현재 회원가입 상태
        final signupFormState = ref.read(signupFormProvider);

        /// 현재 선택된 학년
        final selectedGrade = signupFormState.grade;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 상단 핸들 바
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                /// 바텀시트 제목
                Text(
                  '학년을 선택해주세요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: context.colors.textPrimary,
                  ),
                ),

                SizedBox(height: 8),

                /// 바텀시트 설명
                Text(
                  '현재 재학 중인 학년을 선택하면 다음 단계로 이동할 수 있어요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: context.colors.textMuted,
                  ),
                ),

                SizedBox(height: 20),

                /// 학년 선택 항목
                for (final grade in [1, 2, 3]) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      /// 선택한 학년을 회원가입 상태에 저장
                      ref.read(signupFormProvider.notifier).updateGrade(grade);

                      /// 바텀시트 닫기
                      Navigator.of(bottomSheetContext).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: selectedGrade == grade
                            ? const Color(0xFFF2F5FF)
                            : context.colors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedGrade == grade
                              ? const Color(0xFF4A67F2)
                              : const Color(0xFFE9EDF4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$grade학년',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedGrade == grade
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          if (selectedGrade == grade)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: Color(0xFF4A67F2),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (grade != 3) SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// 회원가입 전체 상태
    final signupFormState = ref.watch(signupFormProvider);

    /// 선택된 학년
    final selectedGrade = signupFormState.grade;

    /// 선택된 학교
    final selectedSchool = signupFormState.selectedSchool;

    /// 학교와 학년이 모두 있어야 다음 버튼 활성화
    final isNextEnabled = selectedSchool != null && selectedGrade != null;

    return AuthStepLayout(
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      bottom: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: isNextEnabled
              ? () {
                  /// 다음 단계인 프로필 정보 입력 페이지로 이동
                  context.push(AppRoutes.signupProfileInfo);
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
            '다음',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
            '2/8',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textTertiary,
            ),
          ),

          SizedBox(height: 14),

          /// 페이지 성격 안내
          Text(
            '재학 정보',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A67F2),
            ),
          ),

          SizedBox(height: 8),

          /// 제목
          Text(
            '몇 학년에 재학 중이신가요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.22,
              color: context.colors.textPrimary,
            ),
          ),

          SizedBox(height: 10),

          /// 보조 문구
          Text(
            '선택한 학교를 기준으로 현재 학년을 알려주세요.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: context.colors.textBody,
            ),
          ),

          SizedBox(height: 28),

          /// 학년 라벨
          Text(
            '학년',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.textMuted,
            ),
          ),

          SizedBox(height: 8),

          /// 학년 선택 영역
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showGradeBottomSheet(context, ref),
            child: Container(
              width: double.infinity,
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedGrade != null
                      ? const Color(0xFF4A67F2)
                      : context.colors.border,
                  width: selectedGrade != null ? 1.3 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedGrade == null ? '학년을 선택해주세요' : '$selectedGrade학년',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedGrade == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                      color: selectedGrade == null
                          ? context.colors.textHint
                          : context.colors.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.colors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 18),

          /// 선택한 학교 라벨
          Text(
            '선택한 학교',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.textMuted,
            ),
          ),

          SizedBox(height: 8),

          /// 이전 단계에서 선택한 학교 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: context.colors.iconSecondary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedSchool?.name ?? '학교를 먼저 선택해주세요.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedSchool != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selectedSchool != null
                          ? context.colors.textPrimary
                          : context.colors.textTertiary,
                    ),
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
