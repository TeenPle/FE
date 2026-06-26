import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/dio_provider.dart';
import '../provider/signup_form_state.dart';

/// 회원가입 API provider
final signupApiProvider = Provider<SignupApi>((ref) {
  final dio = ref.read(dioProvider);
  return SignupApi(dio);
});

class SignupApi {
  final Dio _dio;

  SignupApi(this._dio);

  /// 프론트의 숫자 학년을 백엔드 Grade enum 문자열로 변환
  ///
  /// 1 -> FIRST
  /// 2 -> SECOND
  /// 3 -> THIRD
  String _mapGradeToEnum(int grade) {
    switch (grade) {
      case 1:
        return 'FIRST';
      case 2:
        return 'SECOND';
      case 3:
        return 'THIRD';
      default:
        throw Exception('학년 값이 올바르지 않아요.');
    }
  }

  /// 필수값 검사용 헬퍼
  void _require(bool condition, String message) {
    if (!condition) {
      throw Exception(message);
    }
  }

  /// 회원가입 요청
  ///
  /// 백엔드:
  /// POST /api/auth/signup
  /// multipart/form-data
  /// - data: JSON
  /// - studentCard: 이미지 파일
  ///
  /// [fcmToken]/[fcmPlatform]: 가입 시점에 푸시 토큰을 함께 등록하기 위한 값 (선택).
  /// 인증 승인 전에는 로그인이 차단되어 토큰을 등록할 기회가 없으므로,
  /// 여기서 등록해야 학교 인증 승인/거절 결과를 푸시로 받을 수 있다.
  Future<void> signUp(
    SignupFormState formState, {
    required String password,
    String? fcmToken,
    String? fcmPlatform,
  }) async {
    /// 필수값 체크
    _require(formState.selectedSchool != null, '학교 정보가 없어요.');
    _require(formState.grade != null, '학년 정보가 없어요.');
    _require(formState.username.trim().isNotEmpty, '이름 정보가 없어요.');
    _require(formState.nickname.trim().isNotEmpty, '닉네임 정보가 없어요.');
    _require(formState.gender.trim().isNotEmpty, '성별 정보가 없어요.');
    _require(formState.email.trim().isNotEmpty, '이메일 정보가 없어요.');
    _require(password.trim().isNotEmpty, '비밀번호 정보가 없어요.');
    _require(formState.phoneNumber.trim().isNotEmpty, '전화번호 정보가 없어요.');
    _require(
      formState.verificationToken.trim().isNotEmpty,
      '이메일 인증 토큰 정보가 없어요.',
    );
    _require(formState.studentCardFilePath.trim().isNotEmpty, '학생증 이미지가 없어요.');

    /// gender 값 검증
    _require(
      formState.gender == 'MALE' || formState.gender == 'FEMALE',
      '성별 값이 올바르지 않아요.',
    );

    /// 비밀번호 규칙 사전 체크
    final passwordRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$',
    );
    _require(
      passwordRegex.hasMatch(password.trim()),
      '비밀번호는 영문, 숫자, 특수문자를 포함한 8~20자여야 합니다.',
    );

    /// 닉네임 규칙 사전 체크
    /// - 한글/영어만 가능
    /// - 3~10자
    final nicknameRegex = RegExp(r'^[a-zA-Z가-힣]{3,10}$');
    _require(
      nicknameRegex.hasMatch(formState.nickname.trim()),
      '닉네임은 영어와 한글만 가능하며 3~10자여야 합니다.',
    );

    /// 이름 규칙 사전 체크
    final usernameRegex = RegExp(r'^[a-zA-Z가-힣]{1,20}$');
    _require(
      usernameRegex.hasMatch(formState.username.trim()),
      '이름은 한글과 영어만 가능하며 최대 20자까지 가능해요.',
    );

    /// 백엔드 UserRequestDTO.SignUp 필드명에 맞게 JSON 구성
    final dataJson = jsonEncode({
      'school': formState.selectedSchool!.name,
      'username': formState.username.trim(),
      'password': password.trim(),
      'email': formState.email.trim(),
      'nickname': formState.nickname.trim(),
      'gender': formState.gender.trim(),
      'grade': _mapGradeToEnum(formState.grade!),
      'phoneNumber': formState.phoneNumber.trim(),
      'verificationToken': formState.verificationToken.trim(),
      // 푸시 토큰은 선택값 — 발급 실패 시에도 가입은 정상 진행된다.
      if (fcmToken != null && fcmPlatform != null) ...{
        'fcmToken': fcmToken,
        'fcmPlatform': fcmPlatform,
      },
    });

    /// 파일명 추출
    final fileName = formState.studentCardFilePath.split(RegExp(r'[\\/]')).last;

    /// multipart/form-data 구성
    final formData = FormData.fromMap({
      'data': MultipartFile.fromString(
        dataJson,
        contentType: MediaType('application', 'json'),
      ),
      'studentCard': await MultipartFile.fromFile(
        formState.studentCardFilePath,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/api/auth/signup',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;

    /// 응답 형식 검사
    if (data is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않아요.');
    }

    /// 성공 여부 검사
    if (data['isSuccess'] != true) {
      throw Exception('회원가입에 실패했어요.');
    }
  }
}
