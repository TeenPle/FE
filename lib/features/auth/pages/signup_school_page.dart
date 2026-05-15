import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/keyboard_aware_bottom_bar.dart';
import '../provider/signup_form_provider.dart';
import '../provider/signup_school_provider.dart';

/// 회원가입 1단계 - 학교 검색 및 선택 페이지
class SignupSchoolPage extends ConsumerStatefulWidget {
  const SignupSchoolPage({super.key});

  @override
  ConsumerState<SignupSchoolPage> createState() => _SignupSchoolPageState();
}

class _SignupSchoolPageState extends ConsumerState<SignupSchoolPage> {
  /// 학교명 입력 컨트롤러
  final TextEditingController _schoolController = TextEditingController();

  @override
  void dispose() {
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    /// 학교 검색 전용 상태
    final searchState = ref.watch(signupSchoolProvider);

    /// 최종 회원가입용 상태
    final signupFormState = ref.watch(signupFormProvider);

    /// 현재 선택된 학교
    final selectedSchool = signupFormState.selectedSchool;

    /// 다음 버튼은 실제 학교를 선택했을 때만 활성화
    final isNextEnabled = selectedSchool != null;

    return Scaffold(
      backgroundColor: context.colors.pageBg,

      /// 하단 고정 버튼
      bottomNavigationBar: KeyboardAwareBottomBar(
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: isNextEnabled
                ? () {
              /// 학교는 이미 provider에 저장했으므로
              /// 다음 페이지로 이동만 수행
              context.push(AppRoutes.signupStudentInfo);
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
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
                '1/8',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textTertiary,
                ),
              ),

              SizedBox(height: 14),

              /// 페이지 성격 안내
              Text(
                '학교 정보',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              SizedBox(height: 8),

              /// 제목
              Text(
                '학교를 알려주세요',
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
                '재학 중인 학교를 검색하고 선택해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.colors.textBody,
                ),
              ),

              SizedBox(height: 28),

              /// 학교 라벨
              Text(
                '학교 검색',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
                ),
              ),

              SizedBox(height: 8),

              /// 학교 검색 입력창
              TextField(
                controller: _schoolController,
                onChanged: (value) {
                  /// 검색어 상태 갱신
                  ref.read(signupSchoolProvider.notifier).updateKeyword(value);

                  /// 텍스트가 바뀌면 이전에 선택한 학교/학년/아이디를 초기화
                  /// 현재 provider에는 clearSchool, clearGrade가 없으므로 clear() 사용
                  ref.read(signupFormProvider.notifier).clear();

                  /// 디바운스 없이 바로 학교 검색 API 호출
                  ref.read(signupSchoolProvider.notifier).searchSchools(value);

                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: '학교명을 검색해주세요',
                  hintStyle: TextStyle(color: c.textHint,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: c.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.iconSecondary,
                  ),
                  suffixIcon: _schoolController.text.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      _schoolController.clear();

                      /// 검색어 상태 초기화
                      ref.read(signupSchoolProvider.notifier).updateKeyword('');

                      /// 이전 선택값 초기화
                      ref.read(signupFormProvider.notifier).clear();

                      /// 검색 결과 초기화
                      ref.read(signupSchoolProvider.notifier).searchSchools('');

                      setState(() {});
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.colors.iconSecondary,
                    ),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Color(0xFF4A67F2),
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18),

              /// 에러 메시지
              if (searchState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    searchState.errorMessage!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                ),

              /// 검색 결과 목록
              Expanded(
                child: Builder(
                  builder: (context) {
                    /// 검색어가 없으면 안내 카드 표시
                    if (searchState.keyword.trim().isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE9EDF4),
                          ),
                        ),
                        child: Text(
                          '학교명을 입력하면\n검색 결과가 여기에 표시돼요.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: context.colors.iconSecondary,
                          ),
                        ),
                      );
                    }

                    /// 로딩 중
                    if (searchState.isLoading) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE9EDF4),
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    /// 검색 결과 없음
                    if (searchState.schools.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE9EDF4),
                          ),
                        ),
                        child: Text(
                          '검색 결과가 없어요.\n학교명을 다시 확인해주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: context.colors.textMuted,
                          ),
                        ),
                      );
                    }

                    /// 검색 결과 목록 표시
                    return Container(
                      decoration: BoxDecoration(
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE9EDF4),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                            child: Row(
                              children: [
                                Text(
                                  '검색 결과',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${searchState.schools.length}개',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A67F2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F3F6),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: searchState.schools.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF5F6F8),
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final school = searchState.schools[index];

                                /// 현재 선택된 학교인지 확인
                                final isSelected = selectedSchool?.id == school.id;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    /// 선택한 학교명을 입력창에 반영
                                    _schoolController.text = school.name;
                                    _schoolController.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                            offset: _schoolController.text.length,
                                          ),
                                        );

                                    /// 검색 키워드도 선택 학교명으로 변경
                                    ref
                                        .read(signupSchoolProvider.notifier)
                                        .updateKeyword(school.name);

                                    /// 최종 회원가입 상태에 학교 저장
                                    ref
                                        .read(signupFormProvider.notifier)
                                        .updateSelectedSchool(school);

                                    setState(() {});
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF2F5FF)
                                          : context.colors.cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF4A67F2)
                                            : Colors.transparent,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            school.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: context.colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 20,
                                            color: Color(0xFF4A67F2),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
