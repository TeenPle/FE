import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../provider/signup_form_provider.dart';
import '../provider/signup_phone_check_provider.dart';

/// 회원가입 7단계 - 휴대폰 번호 입력 페이지
class SignupPhonePage extends ConsumerStatefulWidget {
  const SignupPhonePage({super.key});

  @override
  ConsumerState<SignupPhonePage> createState() => _SignupPhonePageState();
}

class _SignupPhonePageState extends ConsumerState<SignupPhonePage> {
  /// 전화번호 입력 컨트롤러
  late final TextEditingController _phoneController;

  /// 디바운스 타이머
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    /// 이전에 입력한 휴대폰 번호가 있으면 복원
    final currentPhoneNumber = ref.read(signupFormProvider).phoneNumber;
    _phoneController = TextEditingController(text: currentPhoneNumber);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  /// 숫자만 남긴 전화번호로 정리
  String _normalizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// 휴대폰 번호 유효성 검사
  bool _isValidPhoneNumber(String value) {
    final normalized = _normalizePhoneNumber(value);
    final regex = RegExp(r'^010\d{8}$');
    return regex.hasMatch(normalized);
  }

  /// 입력값 변경 시 호출
  void _onChanged(String value) {
    final normalized = _normalizePhoneNumber(value);

    /// provider에 즉시 저장
    ref.read(signupFormProvider.notifier).updatePhoneNumber(normalized);

    /// 이전 중복 확인 타이머 취소
    _debounce?.cancel();

    /// 이전 중복 확인 결과 초기화
    ref.read(signupPhoneCheckProvider.notifier).reset();

    setState(() {});

    /// 형식이 맞지 않으면 API 호출 안 함
    if (!_isValidPhoneNumber(normalized)) {
      return;
    }

    /// 500ms 뒤 중복 확인 API 호출
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(signupPhoneCheckProvider.notifier).checkPhone(normalized);
    });
  }

  /// 공통 입력창 스타일
  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
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
      prefixIcon: prefixIcon,
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
    /// 현재 입력값
    final phoneNumber = _normalizePhoneNumber(_phoneController.text);

    /// 전화번호 중복 확인 상태
    final phoneCheckState = ref.watch(signupPhoneCheckProvider);

    /// 형식 유효 여부
    final isValidPhoneNumber = _isValidPhoneNumber(phoneNumber);

    /// 현재 입력값과 마지막 확인값이 같은지 확인
    final isSameAsChecked = phoneCheckState.checkedPhoneNumber == phoneNumber;

    /// 다음 버튼 활성화 조건
    final canProceed =
        isValidPhoneNumber &&
            phoneCheckState.isAvailable == true &&
            isSameAsChecked &&
            !phoneCheckState.isLoading;

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
              /// 최종 번호 한 번 더 저장
              ref
                  .read(signupFormProvider.notifier)
                  .updatePhoneNumber(phoneNumber);

              /// 다음 단계인 학생증 업로드 페이지로 이동
              context.push(AppRoutes.signupStudentCard);
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
                '7/8',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(height: 14),

              /// 페이지 성격 안내
              const Text(
                '연락처 정보',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              const SizedBox(height: 8),

              /// 제목
              const Text(
                '전화번호를 등록해주세요',
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
                '계정 확인과 안내에 사용할 휴대폰 번호예요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF555555),
                ),
              ),

              const SizedBox(height: 28),

              /// 전화번호 라벨
              const Text(
                '휴대폰 번호',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 8),

              /// 전화번호 입력창
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _onChanged,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: _inputDecoration(
                  hintText: '예: 01012345678',
                  prefixIcon: const Icon(
                    Icons.phone_iphone_rounded,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 상태 메시지
              Builder(
                builder: (context) {
                  if (phoneNumber.isEmpty) {
                    return const Text(
                      '예시) 01012345678',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  }

                  if (!isValidPhoneNumber) {
                    return const Text(
                      '예시) 01012345678',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    );
                  }

                  if (phoneCheckState.isLoading) {
                    return const Text(
                      '전화번호 사용 가능 여부를 확인하고 있어요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A67F2),
                      ),
                    );
                  }

                  if (phoneCheckState.errorMessage != null && isSameAsChecked) {
                    return Text(
                      phoneCheckState.errorMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    );
                  }

                  if (phoneCheckState.isAvailable == false && isSameAsChecked) {
                    return const Text(
                      '이미 사용 중인 전화번호예요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    );
                  }

                  if (phoneCheckState.isAvailable == true && isSameAsChecked) {
                    return const Text(
                      '등록 가능한 전화번호예요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A67F2),
                      ),
                    );
                  }

                  return const Text(
                    '예시) 01012345678',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}