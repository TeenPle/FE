import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../provider/signup_form_provider.dart';
import '../provider/signup_nickname_check_provider.dart';

/// 회원가입 3단계 - 이름 / 닉네임 / 성별 입력 페이지
class SignupProfileInfoPage extends ConsumerStatefulWidget {
  const SignupProfileInfoPage({super.key});

  @override
  ConsumerState<SignupProfileInfoPage> createState() =>
      _SignupProfileInfoPageState();
}

class _SignupProfileInfoPageState extends ConsumerState<SignupProfileInfoPage> {
  /// 이름 입력 컨트롤러
  late final TextEditingController _usernameController;

  /// 닉네임 입력 컨트롤러
  late final TextEditingController _nicknameController;

  /// 닉네임 중복 확인 디바운스 타이머
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    /// 이전에 입력한 값이 있으면 복원
    final formState = ref.read(signupFormProvider);
    _usernameController = TextEditingController(text: formState.username);
    _nicknameController = TextEditingController(text: formState.nickname);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  /// 이름 유효성 검사
  ///
  /// 백엔드 규칙:
  /// - 필수
  /// - 최대 20자
  /// - 한글/영어만 가능
  bool _isValidUsername(String value) {
    final trimmed = value.trim();
    final regex = RegExp(r'^[a-zA-Z가-힣]{1,20}$');
    return regex.hasMatch(trimmed);
  }

  /// 닉네임 유효성 검사
  ///
  /// 프론트 규칙:
  /// - 필수
  /// - 3~10자
  /// - 한글/영어만 가능
  bool _isValidNickname(String value) {
    final trimmed = value.trim();
    final regex = RegExp(r'^[a-zA-Z가-힣]{3,10}$');
    return regex.hasMatch(trimmed);
  }

  /// 이름 입력 변경 시 호출
  void _onUsernameChanged(String value) {
    ref.read(signupFormProvider.notifier).updateUsername(value);
    setState(() {});
  }

  /// 닉네임 입력 변경 시 호출
  void _onNicknameChanged(String value) {
    final trimmed = value.trim();

    /// 회원가입 상태에 즉시 저장
    ref.read(signupFormProvider.notifier).updateNickname(value);

    /// 이전 중복 확인 타이머 취소
    _debounce?.cancel();

    /// 이전 중복 확인 상태 초기화
    ref.read(signupNicknameCheckProvider.notifier).reset();

    setState(() {});

    /// 형식이 올바르지 않으면 API 호출 안 함
    if (!_isValidNickname(trimmed)) {
      return;
    }

    /// 500ms 뒤 중복 확인 API 호출
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(signupNicknameCheckProvider.notifier).checkNickname(trimmed);
    });
  }

  /// 성별 버튼 선택 시 호출
  void _onSelectGender(String gender) {
    ref.read(signupFormProvider.notifier).updateGender(gender);
    setState(() {});
  }

  /// 공통 입력창 스타일
  InputDecoration _inputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
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
          width: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 회원가입 전체 상태
    final signupFormState = ref.watch(signupFormProvider);

    /// 닉네임 중복 확인 상태
    final nicknameCheckState = ref.watch(signupNicknameCheckProvider);

    /// 현재 입력값
    final username = _usernameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final gender = signupFormState.gender;

    /// 유효성 검사
    final isUsernameValid = _isValidUsername(username);
    final isNicknameValid = _isValidNickname(nickname);
    final isGenderSelected = gender.isNotEmpty;

    /// 현재 입력 닉네임과 마지막 확인 닉네임이 같은지 확인
    final isSameAsChecked = nicknameCheckState.checkedNickname == nickname;

    /// 다음 버튼 활성화 조건
    final canProceed =
        isUsernameValid &&
            isNicknameValid &&
            isGenderSelected &&
            nicknameCheckState.isAvailable == true &&
            isSameAsChecked &&
            !nicknameCheckState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      /// 하단 고정 버튼
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: canProceed
                ? () {
              /// 최종 입력값 한 번 더 저장
              ref.read(signupFormProvider.notifier).updateUsername(
                username,
              );
              ref.read(signupFormProvider.notifier).updateNickname(
                nickname,
              );

              /// 다음 단계인 이메일 입력 페이지로 이동
              context.push(AppRoutes.signupId);
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
            child: const Text(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              const SizedBox(height: 8),

              /// 단계 표시
              const Text(
                '3/8',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(height: 14),

              /// 페이지 성격 안내
              const Text(
                '프로필 정보',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              const SizedBox(height: 8),

              /// 제목
              const Text(
                '프로필을 설정해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                  letterSpacing: -0.6,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              /// 보조 문구
              const Text(
                'TeenPle에서 사용할 기본 정보를 입력해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF555555),
                ),
              ),

              const SizedBox(height: 28),

              /// 이름 라벨
              const Text(
                '이름',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 이름 입력창
              TextField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                decoration: _inputDecoration(
                  hintText: '이름을 입력해주세요',
                ),
              ),

              const SizedBox(height: 8),

              /// 이름 안내/에러 메시지
              if (username.isNotEmpty && !isUsernameValid)
                const Text(
                  '이름은 한글 또는 영어만 입력할 수 있으며, 최대 20자까지 가능해요.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),

              const SizedBox(height: 16),

              /// 닉네임 라벨
              const Text(
                '닉네임',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 닉네임 입력창
              TextField(
                controller: _nicknameController,
                onChanged: _onNicknameChanged,
                decoration: _inputDecoration(
                  hintText: '닉네임을 입력해주세요',
                ),
              ),

              const SizedBox(height: 8),

              /// 닉네임 상태 메시지
              Builder(
                builder: (context) {
                  if (nickname.isEmpty) {
                    return const Text(
                      '한글 또는 영어로 3~10자까지 사용할 수 있어요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    );
                  }

                  if (!isNicknameValid) {
                    return const Text(
                      '닉네임은 한글 또는 영어로 3~10자 입력해주세요.',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    );
                  }

                  if (nicknameCheckState.isLoading) {
                    return const Text(
                      '닉네임 중복 여부를 확인하고 있어요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A67F2),
                      ),
                    );
                  }

                  if (nicknameCheckState.errorMessage != null &&
                      isSameAsChecked) {
                    return Text(
                      nicknameCheckState.errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    );
                  }

                  if (nicknameCheckState.isAvailable == false &&
                      isSameAsChecked) {
                    return const Text(
                      '이미 사용 중인 닉네임이에요.',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    );
                  }

                  if (nicknameCheckState.isAvailable == true &&
                      isSameAsChecked) {
                    return const Text(
                      '사용 가능한 닉네임이에요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A67F2),
                      ),
                    );
                  }

                  return const Text(
                    '한글 또는 영어로 3~10자까지 사용할 수 있어요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              /// 성별 라벨
              const Text(
                '성별',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 성별 선택 설명
              const Text(
                '프로필에 표시할 성별을 선택해주세요.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A8A8A),
                ),
              ),

              const SizedBox(height: 12),

              /// 성별 선택 버튼
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onSelectGender('MALE'),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gender == 'MALE'
                              ? const Color(0xFFF2F5FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gender == 'MALE'
                                ? const Color(0xFF4A67F2)
                                : const Color(0xFFE3E7EF),
                            width: gender == 'MALE' ? 1.3 : 1.0,
                          ),
                        ),
                        child: Text(
                          '남성',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: gender == 'MALE'
                                ? const Color(0xFF4A67F2)
                                : const Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onSelectGender('FEMALE'),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gender == 'FEMALE'
                              ? const Color(0xFFF2F5FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gender == 'FEMALE'
                                ? const Color(0xFF4A67F2)
                                : const Color(0xFFE3E7EF),
                            width: gender == 'FEMALE' ? 1.3 : 1.0,
                          ),
                        ),
                        child: Text(
                          '여성',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: gender == 'FEMALE'
                                ? const Color(0xFF4A67F2)
                                : const Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (!isGenderSelected && (username.isNotEmpty || nickname.isNotEmpty))
                const Text(
                  '성별을 선택해주세요.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}