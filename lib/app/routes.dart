import 'package:go_router/go_router.dart';

import '../features/admin/pages/admin_home_page.dart';
import '../features/admin/pages/admin_verification_detail_page.dart';
import '../features/admin/pages/admin_verification_list_page.dart';
import '../features/auth/pages/landing_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/school_verification_rejected_page.dart';
import '../features/auth/pages/school_verification_waiting_page.dart';
import '../features/auth/pages/signup_email_verify_page.dart';
import '../features/auth/pages/signup_id_page.dart';
import '../features/auth/pages/signup_password_page.dart';
import '../features/auth/pages/signup_phone_page.dart';
import '../features/auth/pages/signup_profile_info_page.dart';
import '../features/auth/pages/signup_school_page.dart';
import '../features/auth/pages/signup_student_card_page.dart';
import '../features/auth/pages/signup_student_info_page.dart';
import '../features/post/pages/post_detail_page.dart';
import '../features/post/pages/write_post_page.dart';
import '../features/school/pages/board_detail_page.dart';
import '../features/school/pages/school_page.dart';
import '../features/search/pages/search_page.dart';

/// 앱 전체에서 사용하는 라우트 경로 상수
class AppRoutes {
  /// 시작 랜딩 페이지
  static const landing = '/landing';

  /// 로그인 페이지
  static const login = '/login';

  /// 회원가입 1단계 - 학교 선택 페이지
  static const signupSchool = '/signup/school';

  /// 회원가입 2단계 - 학년 입력 페이지
  static const signupStudentInfo = '/signup/student-info';

  /// 회원가입 3단계 - 이름/닉네임/성별 입력 페이지
  static const signupProfileInfo = '/signup/profile-info';

  /// 회원가입 4단계 - 이메일 입력 페이지
  static const signupId = '/signup/id';

  /// 회원가입 5단계 - 이메일 인증 페이지
  static const signupEmailVerify = '/signup/email-verify';

  /// 회원가입 6단계 - 비밀번호 설정 페이지
  static const signupPassword = '/signup/password';

  /// 회원가입 7단계 - 전화번호 입력 페이지
  static const signupPhone = '/signup/phone';

  /// 회원가입 8단계 - 학생증 업로드 페이지
  static const signupStudentCard = '/signup/student-card';

  /// 학교 인증 대기/필수/상태이상 안내 페이지
  static const schoolVerificationWaiting =
      '/auth/school-verification-waiting';

  /// 학교 인증 반려 페이지
  static const schoolVerificationRejected =
      '/auth/school-verification-rejected';

  /// 관리자 메인 페이지
  static const adminHome = '/admin/home';

  /// 관리자 인증 요청 목록 페이지
  static const adminVerificationList = '/admin/verification-requests';

  /// 로그인 완료 후 진입할 일반 유저 메인 페이지
  static const school = '/school';

  /// 게시판 상세 페이지
  static const boardDetail = '/board/:boardId';

  /// 게시글 작성/수정 페이지
  static const writePost = '/write-post';

  /// 검색 페이지
  static const search = '/search';
}

/// 앱 전체 라우터
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.landing,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => AppRoutes.landing,
    ),

    GoRoute(
      path: AppRoutes.landing,
      builder: (context, state) => const LandingPage(),
    ),

    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: AppRoutes.signupSchool,
      builder: (context, state) => const SignupSchoolPage(),
    ),

    GoRoute(
      path: AppRoutes.signupStudentInfo,
      builder: (context, state) => const SignupStudentInfoPage(),
    ),

    GoRoute(
      path: AppRoutes.signupProfileInfo,
      builder: (context, state) => const SignupProfileInfoPage(),
    ),

    GoRoute(
      path: AppRoutes.signupId,
      builder: (context, state) => const SignupIdPage(),
    ),

    GoRoute(
      path: AppRoutes.signupEmailVerify,
      builder: (context, state) => const SignupEmailVerifyPage(),
    ),

    GoRoute(
      path: AppRoutes.signupPassword,
      builder: (context, state) => const SignupPasswordPage(),
    ),

    GoRoute(
      path: AppRoutes.signupPhone,
      builder: (context, state) => const SignupPhonePage(),
    ),

    GoRoute(
      path: AppRoutes.signupStudentCard,
      builder: (context, state) => const SignupStudentCardPage(),
    ),

    GoRoute(
      path: AppRoutes.schoolVerificationWaiting,
      builder: (context, state) => const SchoolVerificationWaitingPage(),
    ),

    GoRoute(
      path: AppRoutes.schoolVerificationRejected,
      builder: (context, state) => const SchoolVerificationRejectedPage(),
    ),

    GoRoute(
      path: AppRoutes.adminHome,
      builder: (context, state) => const AdminHomePage(),
    ),

    GoRoute(
      path: AppRoutes.adminVerificationList,
      builder: (context, state) => const AdminVerificationListPage(),
    ),

    GoRoute(
      path: '${AppRoutes.adminVerificationList}/:requestId',
      builder: (context, state) {
        final requestId = int.parse(state.pathParameters['requestId']!);
        return AdminVerificationDetailPage(requestId: requestId);
      },
    ),

    GoRoute(
      path: AppRoutes.school,
      builder: (context, state) => const SchoolPage(),
    ),

    GoRoute(
      path: '/post/:postId',
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['postId']!);
        return PostDetailPage(postId: postId);
      },
    ),

    GoRoute(
      path: '/board/:boardId',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BoardDetailPage(
          boardId: extra['boardId'] as int,
          boardTitle: extra['boardTitle'] as String,
        );
      },
    ),

    GoRoute(
      path: '/write-post',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return WritePostPage(
          boardId: extra['boardId'] as int,
          boardTitle: extra['boardTitle'] as String,
          isEditMode: extra['isEditMode'] as bool? ?? false,
          postId: extra['postId'] as int?,
          initialTitle: extra['initialTitle'] as String?,
          initialContent: extra['initialContent'] as String?,
          initialAnonymous: extra['initialAnonymous'] as bool?,
        );
      },
    ),

    GoRoute(
      path: '/search',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchPage(
          initialKeyword: extra?['keyword'] as String?,
        );
      },
    ),
  ],
);