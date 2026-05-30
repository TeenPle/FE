import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/token_storage.dart';
import '../features/admin/pages/admin_home_page.dart';
import '../features/admin/pages/admin_ad_page.dart';
import '../features/admin/pages/admin_audit_log_page.dart';
import '../features/admin/pages/admin_board_posts_page.dart';
import '../features/admin/pages/admin_post_detail_page.dart';
import '../features/admin/pages/admin_report_detail_page.dart';
import '../features/admin/pages/admin_penalty_list_page.dart';
import '../features/admin/pages/admin_report_list_page.dart';
import '../features/admin/pages/admin_school_boards_page.dart';
import '../features/admin/pages/admin_school_list_page.dart';
import '../features/admin/pages/admin_user_history_page.dart';
import '../features/admin/pages/admin_verification_detail_page.dart';
import '../features/admin/pages/admin_verification_list_page.dart';
import '../features/inquiry/pages/admin_inquiry_detail_page.dart';
import '../features/inquiry/pages/admin_inquiry_list_page.dart';
import '../features/inquiry/pages/inquiry_detail_page.dart';
import '../features/inquiry/pages/inquiry_page.dart';
import '../features/inquiry/pages/inquiry_write_page.dart';
import '../features/warning/pages/my_warning_history_page.dart';
import '../features/auth/pages/find_email_page.dart';
import '../features/auth/pages/find_email_result_page.dart';
import '../features/auth/pages/find_password_page.dart';
import '../features/auth/pages/reset_password_page.dart';
import '../features/auth/pages/landing_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/signup_consent_page.dart';
import '../features/auth/pages/account_delete_confirm_page.dart';
import '../features/auth/pages/account_recovery_page.dart';
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
import '../features/meal/pages/meal_page.dart';
import '../features/penalty/pages/my_penalty_page.dart';
import '../features/notification/pages/notification_page.dart';
import '../features/timetable/pages/timetable_page.dart';
import '../features/post/pages/post_detail_page.dart';
import '../features/post/pages/write_post_page.dart';
import '../features/profile/pages/edit_nickname_page.dart';
import '../features/profile/pages/edit_password_page.dart';
import '../features/profile/pages/my_comments_page.dart';
import '../features/profile/pages/my_bookmarks_page.dart';
import '../features/profile/pages/my_liked_posts_page.dart';
import '../features/profile/pages/my_posts_page.dart';
import '../features/dday/pages/dday_settings_page.dart';
import '../features/school/pages/hot_board_page.dart';
import '../features/profile/pages/privacy_policy_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/profile/pages/settings_page.dart';
import '../features/profile/pages/terms_page.dart';
import '../features/chat/pages/chat_room_list_page.dart';
import '../features/chat/pages/chat_room_page.dart';
import '../features/school/models/board_model.dart';
import '../features/school/pages/board_detail_page.dart';
import '../features/school/pages/school_page.dart';
import '../features/search/pages/search_page.dart';

/// ???꾩껜?먯꽌 ?ъ슜?섎뒗 ?쇱슦??寃쎈줈 ?곸닔
class AppRoutes {
  /// ?쒖옉 ?쒕뵫 ?섏씠吏
  static const landing = '/landing';

  /// 濡쒓렇???섏씠吏
  static const login = '/login';

  /// ?뚯썝媛??1?④퀎 - ?숆탳 ?좏깮 ?섏씠吏
  /// 회원가입 동의 페이지 (약관·개인정보·연령 동의)
  static const signupConsent = '/signup/consent';

  static const signupSchool = '/signup/school';

  /// ?뚯썝媛??2?④퀎 - ?숇뀈 ?낅젰 ?섏씠吏
  static const signupStudentInfo = '/signup/student-info';

  /// ?뚯썝媛??3?④퀎 - ?대쫫/?됰꽕???깅퀎 ?낅젰 ?섏씠吏
  static const signupProfileInfo = '/signup/profile-info';

  /// ?뚯썝媛??4?④퀎 - ?대찓???낅젰 ?섏씠吏
  static const signupId = '/signup/id';

  /// ?뚯썝媛??5?④퀎 - ?대찓???몄쬆 ?섏씠吏
  static const signupEmailVerify = '/signup/email-verify';

  /// ?뚯썝媛??6?④퀎 - 鍮꾨?踰덊샇 ?ㅼ젙 ?섏씠吏
  static const signupPassword = '/signup/password';

  /// ?뚯썝媛??7?④퀎 - ?꾪솕踰덊샇 ?낅젰 ?섏씠吏
  static const signupPhone = '/signup/phone';

  /// ?뚯썝媛??8?④퀎 - ?숈깮利??낅줈???섏씠吏
  static const signupStudentCard = '/signup/student-card';

  /// ?숆탳 ?몄쬆 ?湲??꾩닔/?곹깭?댁긽 ?덈궡 ?섏씠吏
  static const schoolVerificationWaiting = '/auth/school-verification-waiting';
  static const accountRecovery = '/auth/account-recovery';
  static const accountDeleteConfirm = '/profile/account-delete-confirm';

  /// ?숆탳 ?몄쬆 諛섎젮 ?섏씠吏
  static const schoolVerificationRejected =
      '/auth/school-verification-rejected';

  /// 愿由ъ옄 硫붿씤 ?섏씠吏
  static const adminHome = '/admin/home';

  /// 愿由ъ옄 ?숆탳 紐⑤땲?곕쭅
  static const adminSchools = '/admin/schools';

  /// 관리자 학교별 게시판
  static String adminSchoolBoards(int schoolId) =>
      '/admin/schools/$schoolId/boards';

  /// 愿由ъ옄 寃뚯떆?먮퀎 寃뚯떆湲
  static String adminBoardPosts(int boardId) => '/admin/boards/$boardId/posts';

  /// 愿由ъ옄 寃뚯떆湲 ?곸꽭
  static String adminPostDetail(int postId) => '/admin/posts/$postId';

  /// 愿由ъ옄 ?몄쬆 ?붿껌 紐⑸줉 ?섏씠吏
  static const adminVerificationList = '/admin/verification-requests';

  /// 愿由ъ옄 ?좉퀬 紐⑸줉 ?섏씠吏
  static const adminReportList = '/admin/reports';

  /// 愿由ъ옄 ?쒖옱 紐⑸줉 ?섏씠吏
  static const adminPenaltyList = '/admin/penalties';

  /// 愿由ъ옄 媛먯궗 濡쒓렇 ?섏씠吏
  static const adminAuditLogs = '/admin/audit-logs';

  static const adminInquiries = '/admin/inquiries';
  static const adminAds = '/admin/ads';

  /// 愿由ъ옄 ?좉퀬 ?곸꽭 ?섏씠吏
  static String adminReportDetail(int id) => '/admin/reports/$id';

  static String adminInquiryDetail(int id) => '/admin/inquiries/$id';

  /// 濡쒓렇???꾨즺 ??吏꾩엯???쇰컲 ?좎? 硫붿씤 ?섏씠吏
  static const school = '/school';

  /// 寃뚯떆???곸꽭 ?섏씠吏
  static const boardDetail = '/board/:boardId';

  /// 寃뚯떆湲 ?묒꽦/?섏젙 ?섏씠吏
  static const writePost = '/write-post';

  /// 寃???섏씠吏
  static const search = '/search';

  /// ???꾨줈???섏씠吏
  static const profile = '/profile';

  /// ?됰꽕??蹂寃??섏씠吏
  static const editNickname = '/profile/edit-nickname';

  /// 鍮꾨?踰덊샇 蹂寃??섏씠吏
  static const editPassword = '/settings/edit-password';

  /// ?닿? ??湲 ?섏씠吏
  static const myPosts = '/profile/my-posts';

  /// ?닿? ???볤? ?섏씠吏
  static const myComments = '/profile/my-comments';

  /// ?ㅼ젙 ?섏씠吏
  static const settings = '/settings';

  /// ?닿? 怨듦컧??湲 ?섏씠吏
  static const myLikedPosts = '/profile/liked-posts';

  /// ?쒖옱 ?대젰 ?섏씠吏
  static const myPenalties = '/settings/penalties';

  /// ?뚮┝ 紐⑸줉 ?섏씠吏
  static const notifications = '/notifications';

  /// 湲됱떇 ?섏씠吏
  static const meal = '/meal';

  /// ?쒓컙???섏씠吏
  static const timetable = '/timetable';

  /// 梨꾪똿諛?紐⑸줉 ?섏씠吏
  static const chat = '/chat';

  /// 梨꾪똿諛??곸꽭 ?섏씠吏
  static const chatRoom = '/chat/rooms/:roomId';

  /// ?꾩씠??李얘린 ?섏씠吏
  static const findEmail = '/find-email';

  /// ?꾩씠??李얘린 寃곌낵 ?섏씠吏
  static const findEmailResult = '/find-email/result';

  /// 鍮꾨?踰덊샇 李얘린 ?섏씠吏
  static const findPassword = '/find-password';

  /// 鍮꾨?踰덊샇 ?ъ꽕???섏씠吏
  static const resetPassword = '/find-password/reset';

  /// ?댁슜?쎄? ?섏씠吏
  static const terms = '/settings/terms';

  /// 媛쒖씤?뺣낫泥섎━諛⑹묠 ?섏씠吏
  static const privacyPolicy = '/settings/privacy-policy';

  /// D-Day ?ㅼ젙 ?섏씠吏
  static const ddaySettings = '/settings/dday';

  /// HOT 寃뚯떆???꾩껜 蹂닿린
  static const hotBoard = '/hot';

  /// ??遺곷쭏???섏씠吏
  static const myBookmarks = '/profile/bookmarks';

  /// ??寃쎄퀬 ?대젰 ?섏씠吏
  static const myWarnings = '/profile/warnings';

  static const inquiries = '/profile/inquiries';
  static const inquiryWrite = '/profile/inquiries/write';
  static String inquiryDetail(int id) => '/profile/inquiries/$id';

  /// 愿由ъ옄 ?좎?蹂??쒖옱쨌寃쎄퀬 ?대젰 ?섏씠吏
  static String adminUserHistory(int userId) => '/admin/users/$userId/history';
}

/// ???꾩껜 ?쇱슦??
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.landing,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => AppRoutes.landing),

    GoRoute(
      path: AppRoutes.landing,
      builder: (context, state) => const LandingPage(),
    ),

    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: AppRoutes.signupConsent,
      builder: (context, state) => const SignupConsentPage(),
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
      path: AppRoutes.accountRecovery,
      builder: (context, state) => const AccountRecoveryPage(),
    ),

    GoRoute(
      path: AppRoutes.accountDeleteConfirm,
      builder: (context, state) => const AccountDeleteConfirmPage(),
    ),

    GoRoute(
      path: AppRoutes.adminHome,
      redirect: _adminOnly,
      builder: (context, state) => const AdminHomePage(),
    ),

    GoRoute(
      path: AppRoutes.adminSchools,
      redirect: _adminOnly,
      builder: (context, state) => const AdminSchoolListPage(),
    ),

    GoRoute(
      path: '/admin/schools/:schoolId/boards',
      redirect: _adminOnly,
      builder: (context, state) {
        final schoolId = int.parse(state.pathParameters['schoolId']!);
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        return AdminSchoolBoardsPage(
          schoolId: schoolId,
          schoolName: extra?['schoolName'] as String? ?? '학교 게시판',
        );
      },
    ),

    GoRoute(
      path: '/admin/boards/:boardId/posts',
      redirect: _adminOnly,
      builder: (context, state) {
        final boardId = int.parse(state.pathParameters['boardId']!);
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        return AdminBoardPostsPage(
          boardId: boardId,
          boardTitle: extra?['boardTitle'] as String? ?? '게시글 목록',
          schoolName: extra?['schoolName'] as String?,
        );
      },
    ),

    GoRoute(
      path: '/admin/posts/:postId',
      redirect: _adminOnly,
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['postId']!);
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        return AdminPostDetailPage(
          postId: postId,
          focusCommentId: extra?['focusCommentId'] as int?,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.adminVerificationList,
      redirect: _adminOnly,
      builder: (context, state) => const AdminVerificationListPage(),
    ),

    GoRoute(
      path: '${AppRoutes.adminVerificationList}/:requestId',
      redirect: _adminOnly,
      builder: (context, state) {
        final requestId = int.parse(state.pathParameters['requestId']!);
        return AdminVerificationDetailPage(requestId: requestId);
      },
    ),

    GoRoute(
      path: AppRoutes.adminReportList,
      redirect: _adminOnly,
      builder: (context, state) => const AdminReportListPage(),
    ),

    GoRoute(
      path: AppRoutes.adminPenaltyList,
      redirect: _adminOnly,
      builder: (context, state) => const AdminPenaltyListPage(),
    ),

    GoRoute(
      path: AppRoutes.adminAuditLogs,
      redirect: _adminOnly,
      builder: (context, state) => const AdminAuditLogPage(),
    ),
    GoRoute(
      path: AppRoutes.adminAds,
      redirect: _adminOnly,
      builder: (context, state) => const AdminAdPage(),
    ),
    GoRoute(
      path: AppRoutes.adminInquiries,
      redirect: _adminOnly,
      builder: (context, state) => const AdminInquiryListPage(),
    ),
    GoRoute(
      path: '/admin/inquiries/:inquiryId',
      redirect: _adminOnly,
      builder: (context, state) {
        final inquiryId = int.parse(state.pathParameters['inquiryId']!);
        return AdminInquiryDetailPage(inquiryId: inquiryId);
      },
    ),

    GoRoute(
      path: '/admin/reports/:reportId',
      redirect: _adminOnly,
      builder: (context, state) {
        final reportId = int.parse(state.pathParameters['reportId']!);
        return AdminReportDetailPage(reportId: reportId);
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
        final boardId = int.parse(state.pathParameters['boardId']!);
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        return BoardDetailPage(
          boardId: extra?['boardId'] as int? ?? boardId,
          boardTitle: extra?['boardTitle'] as String? ?? '게시판',
        );
      },
    ),

    GoRoute(
      path: '/write-post',
      builder: (context, state) {
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic>
            ? rawExtra
            : const <String, dynamic>{};
        final availableBoards = extra['availableBoards'];
        return WritePostPage(
          boardId: extra['boardId'] as int?,
          boardTitle: extra['boardTitle'] as String? ?? '',
          availableBoards: availableBoards is List<BoardModel>
              ? availableBoards
              : const [],
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
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        return SearchPage(
          initialKeyword: extra?['keyword'] as String?,
          boardId: extra?['boardId'] as int?,
          scopeTitle: extra?['scopeTitle'] as String?,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),

    GoRoute(
      path: AppRoutes.editNickname,
      builder: (context, state) => const EditNicknamePage(),
    ),

    GoRoute(
      path: AppRoutes.editPassword,
      builder: (context, state) => const EditPasswordPage(),
    ),

    GoRoute(
      path: AppRoutes.myPosts,
      builder: (context, state) => const MyPostsPage(),
    ),

    GoRoute(
      path: AppRoutes.myComments,
      builder: (context, state) => const MyCommentsPage(),
    ),

    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),

    GoRoute(
      path: AppRoutes.myPenalties,
      builder: (context, state) => const MyPenaltyPage(),
    ),

    GoRoute(
      path: AppRoutes.myLikedPosts,
      builder: (context, state) => const MyLikedPostsPage(),
    ),

    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationPage(),
    ),

    GoRoute(
      path: AppRoutes.meal,
      builder: (context, state) => const MealPage(),
    ),

    GoRoute(
      path: AppRoutes.timetable,
      builder: (context, state) => const TimetablePage(),
    ),

    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatRoomListPage(),
    ),

    GoRoute(
      path: '/chat/rooms/:roomId',
      builder: (context, state) {
        final roomId = int.parse(state.pathParameters['roomId']!);
        final rawExtra = state.extra;
        if (rawExtra is! Map<String, dynamic>) {
          return const ChatRoomListPage();
        }
        final extra = rawExtra;
        return ChatRoomPage(
          roomId: roomId,
          otherUserId: (extra['otherUserId'] as num).toInt(),
          displayName: extra['displayName'] as String? ?? '채팅방',
          initialBlocked: extra['blocked'] as bool? ?? false,
          initialBlockedByMe: extra['blockedByMe'] as bool? ?? false,
          initialBlockedByOther: extra['blockedByOther'] as bool? ?? false,
          initialOtherUserDeleted: extra['otherUserDeleted'] as bool? ?? false,
          initialCanSendMessage: extra['canSendMessage'] as bool? ?? true,
          initialCanReport: extra['canReport'] as bool? ?? true,
          initialCanBlock: extra['canBlock'] as bool? ?? true,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.findEmail,
      builder: (context, state) => const FindEmailPage(),
    ),

    GoRoute(
      path: AppRoutes.findEmailResult,
      builder: (context, state) {
        final maskedEmail = state.extra;
        if (maskedEmail is! String || maskedEmail.isEmpty) {
          return const FindEmailPage();
        }
        return FindEmailResultPage(maskedEmail: maskedEmail);
      },
    ),

    GoRoute(
      path: AppRoutes.findPassword,
      builder: (context, state) => const FindPasswordPage(),
    ),

    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) {
        final token = state.extra;
        if (token is! String || token.isEmpty) {
          return const FindPasswordPage();
        }
        return ResetPasswordPage(verificationToken: token);
      },
    ),

    GoRoute(
      path: AppRoutes.terms,
      builder: (context, state) => const TermsPage(),
    ),

    GoRoute(
      path: AppRoutes.privacyPolicy,
      builder: (context, state) => const PrivacyPolicyPage(),
    ),

    GoRoute(
      path: AppRoutes.ddaySettings,
      builder: (context, state) => const DDaySettingsPage(),
    ),

    GoRoute(
      path: AppRoutes.hotBoard,
      builder: (context, state) => const HotBoardPage(),
    ),

    GoRoute(
      path: AppRoutes.myBookmarks,
      builder: (context, state) => const MyBookmarksPage(),
    ),

    GoRoute(
      path: AppRoutes.myWarnings,
      builder: (context, state) => const MyWarningHistoryPage(),
    ),
    GoRoute(
      path: AppRoutes.inquiries,
      builder: (context, state) => const InquiryPage(),
    ),
    GoRoute(
      path: AppRoutes.inquiryWrite,
      builder: (context, state) => const InquiryWritePage(),
    ),
    GoRoute(
      path: '/profile/inquiries/:inquiryId',
      builder: (context, state) {
        final inquiryId = int.parse(state.pathParameters['inquiryId']!);
        return InquiryDetailPage(inquiryId: inquiryId);
      },
    ),

    GoRoute(
      path: '/admin/users/:userId/history',
      redirect: _adminOnly,
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        final nickname = extra?['nickname'] as String? ?? '';
        return AdminUserHistoryPage(userId: userId, userNickname: nickname);
      },
    ),
  ],
);

Future<String?> _adminOnly(BuildContext context, GoRouterState state) async {
  final storage = TokenStorage();
  // 로그인 직후 세션 토큰은 메모리에만 있을 수 있으므로 저장된 사용자와 역할로 가드를 판단한다.
  final userId = await storage.getUserId();
  if (userId == null) return AppRoutes.login;
  final role = await storage.getUserRole();
  if (role != 'ADMIN') return AppRoutes.login;
  return null;
}
