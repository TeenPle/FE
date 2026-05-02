import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dio 인스턴스를 전역으로 주입하기 위한 provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      /// 실제 백엔드 서버 주소로 변경해야 함
      /// 안드로이드 에뮬레이터에서 로컬 서버 접근 시 보통 10.0.2.2 사용
      // baseUrl: 'http://localhost:8080',
      baseUrl: 'http://10.0.2.2:8080',
      /// 요청 타임아웃 설정
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),

      /// 기본 헤더
      headers: {        'Content-Type': 'application/json',
      },
    ),
  );
});