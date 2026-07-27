# TeenPle 게시글 공유 기능 구현 계획

작성일: 2026-07-26

## 1. 목표

TeenPle 앱의 게시글 상세 화면에서 공유 버튼을 누르면 게시글 링크를 생성하고, 사용자는 Android/iOS 기본 공유창을 통해 카카오톡, 인스타그램, 문자, 링크 복사 등 원하는 앱으로 공유할 수 있게 한다.

공유받은 사용자가 링크를 눌렀을 때의 목표 동작은 다음과 같다.

1. TeenPle 앱이 설치되어 있으면 앱이 열리고 해당 게시글 상세 화면으로 이동한다.
2. TeenPle 앱이 설치되어 있지 않으면 웹 fallback 페이지가 열리고, App Store 또는 Google Play 다운로드로 안내한다.
3. 외부 웹에서는 게시글 본문, 댓글, 작성자 등 실제 콘텐츠를 노출하지 않는다.
4. 게시글 접근 권한, 로그인 여부, 학교 인증 여부는 앱 내부 기존 정책에 따라 처리한다.

## 2. 구현 범위

이번 공유 기능은 카카오톡 전용 템플릿 메시지나 인스타그램 전용 API 연동이 아니다.

구현 범위:

- 게시글 공유 URL 생성
- Flutter 기본 공유창 호출
- Android App Links 설정
- iOS Universal Links 설정
- 앱에서 딥링크 수신 후 게시글 상세 이동
- 앱 미설치자를 위한 웹 fallback 페이지
- Play Store/App Store 다운로드 버튼 제공
- 기능 플래그로 공유 버튼 노출 제어

구현하지 않는 범위:

- Kakao Developers 카카오톡 공유 템플릿 연동
- Kakao Biz 앱 전환
- 인스타그램 전용 SDK 연동
- 앱 미설치 후 설치 완료 시 원래 게시글로 자동 이동하는 deferred deep link
- 외부 웹에서 게시글 본문 미리보기 제공
- 게시글별 Open Graph 제목/이미지 동적 생성

## 3. 사업자/외부 개발자 계정 필요 여부

현재 원하는 방식에서는 사업자등록이 필요하지 않다.

이유:

- 카카오톡 공유는 OS 기본 공유창을 통해 단순 URL 텍스트를 공유한다.
- 카카오톡 전용 카드 템플릿, 메시지 템플릿, 카카오 SDK 기반 공유 API를 사용하지 않는다.
- 인스타그램도 OS 기본 공유창 또는 링크 복사 중심으로 처리한다.
- Android App Links와 iOS Universal Links는 앱 소유 도메인과 스토어 앱 정보가 있으면 구현 가능하다.

사업자 또는 별도 심사가 필요할 수 있는 경우:

- Kakao Developers의 일부 고급 권한, Biz 앱 전환, 카카오톡 메시지 API 등을 사용하는 경우
- 인스타그램/Meta 공식 SDK로 스토리, 피드 등 특정 공유 기능을 깊게 연동하는 경우
- 마케팅 분석용 딥링크 SaaS에서 사업자 인증 또는 유료 플랜을 요구하는 경우

현재 요구사항에서는 위 기능을 사용하지 않는다.

## 4. 최종 사용자 흐름

### 4.1 공유하는 사용자

1. 사용자가 앱에서 게시글 상세 화면에 진입한다.
2. 공유 버튼을 누른다.
3. 앱이 아래 형식의 링크를 생성한다.

```text
https://teenple.app/post/{postId}
```

예시:

```text
https://teenple.app/post/123
```

4. Android/iOS 기본 공유창이 열린다.
5. 사용자는 카카오톡, 인스타그램, 문자, 복사, 기타 앱 중 하나를 선택한다.
6. 선택한 앱에는 링크와 짧은 안내 문구가 전달된다.

공유 문구 예시:

```text
TeenPle에서 게시글 보기
https://teenple.app/post/123
```

또는 게시글 제목을 포함할 경우:

```text
{게시글 제목}

TeenPle 앱에서 보기
https://teenple.app/post/123
```

주의:

- 공유 문구에 게시글 본문 전체를 넣지 않는다.
- 작성자 표시명, 댓글 내용, 학교명 등 민감하거나 맥락이 필요한 정보는 외부 공유 문구에 넣지 않는다.
- 게시글 제목 포함 여부는 정책적으로 한 번 더 판단한다. 학교 인증 기반 커뮤니티 특성상 제목도 외부 노출이 부담되면 제목 없이 공유한다.

### 4.2 링크를 받은 사용자: 앱 설치됨

1. 사용자가 카카오톡/문자/브라우저 등에서 `https://teenple.app/post/123`을 누른다.
2. OS가 도메인 연결을 확인한다.
3. TeenPle 앱이 설치되어 있고 App Links/Universal Links 검증이 되어 있으면 앱이 열린다.
4. 앱은 URI에서 `postId=123`을 파싱한다.
5. 로그인/학교 인증 상태를 확인한다.
6. 접근 가능하면 기존 게시글 상세 화면으로 이동한다.

앱 내부 라우트:

```text
/post/:postId
```

현재 프로젝트에는 이미 `/post/:postId` GoRouter 라우트가 존재한다.

### 4.3 링크를 받은 사용자: 앱 미설치

1. 사용자가 `https://teenple.app/post/123`을 누른다.
2. 앱이 없으므로 브라우저에서 웹 fallback 페이지가 열린다.
3. 웹 페이지에는 게시글 내용 대신 앱 설치 안내만 보여준다.
4. Android면 Google Play 버튼, iOS면 App Store 버튼을 강조한다.
5. PC나 OS 판별이 애매하면 두 버튼을 모두 보여준다.

fallback 페이지 핵심 문구:

```text
TeenPle 앱에서 게시글을 확인해 주세요.
학교 인증을 완료한 고등학생만 게시글을 볼 수 있습니다.
```

## 5. URL 정책

공유 URL은 아래 형식을 사용한다.

```text
https://teenple.app/post/{postId}
```

선택 이유:

- 현재 앱 내부 라우트가 `/post/:postId`로 이미 존재한다.
- 웹 fallback과 앱 라우팅 경로를 동일하게 맞출 수 있다.
- 사용자에게 보이는 URL이 짧고 이해하기 쉽다.
- `teenple.app` 공식 도메인을 사용하므로 신뢰도가 높다.

사용하지 않을 URL:

```text
teenple://post/123
https://api.teenple.app/posts/123
https://teenple.page.link/...
```

이유:

- custom scheme은 앱 미설치 fallback이 약하다.
- API 도메인은 사용자 공유용 링크로 부적절하다.
- Firebase Dynamic Links는 종료된 서비스라 신규 사용하지 않는다.

## 6. 개인정보/운영 정책

TeenPle은 학교 인증 기반 고등학생 커뮤니티다. 따라서 공유 기능은 유입보다 안전한 접근 제어가 우선이다.

정책:

- 외부 웹 fallback에서는 게시글 제목/본문/댓글/작성자 정보를 노출하지 않는다.
- 실제 게시글 내용은 앱에서 로그인 및 학교 인증 후 서버 권한 검사를 통과해야 볼 수 있다.
- 삭제된 게시글, 숨김 처리된 게시글, 차단한 사용자의 게시글, 다른 학교/권한 밖 게시글은 기존 앱 오류 처리에 따른다.
- 공유 링크 자체는 단순 식별자 URL이며, 접근 권한을 우회하는 토큰을 포함하지 않는다.
- 링크에 JWT, refresh token, userId, schoolId 등 사용자 정보를 넣지 않는다.

## 7. 현재 프로젝트에서 확인된 상태

현재 확인된 값:

```text
도메인: teenple.app
Android applicationId: com.teenple.teenple_frontend
iOS Bundle ID: com.teenple.teenpleFrontend
앱 내부 게시글 상세 라우트: /post/:postId
공유 기능 플래그: POST_SHARING_ENABLED
현재 기본값: false
```

현재 있는 파일:

```text
lib/core/config/feature_flags.dart
lib/core/config/web_links.dart
lib/app/routes.dart
```

현재 필요한 작업:

- `share_plus` dependency 추가
- `app_links` 또는 Flutter/go_router 딥링크 수신 처리 추가
- AndroidManifest App Links intent-filter 추가
- iOS Associated Domains entitlement 추가
- `assetlinks.json` 생성 및 배포
- `apple-app-site-association` 생성 및 배포
- `/post/{postId}` 웹 fallback 페이지 추가
- CloudFront/S3 rewrite 설정 점검
- 게시글 상세 화면 공유 버튼 연결
- `POST_SHARING_ENABLED=true` 빌드에서 공유 버튼 노출

## 8. Flutter 공유 버튼 구현 계획

### 8.1 dependency

권장 dependency:

```yaml
dependencies:
  share_plus: <현재 Flutter SDK와 호환되는 최신 버전>
```

명령 예시:

```powershell
flutter pub add share_plus
flutter pub get
```

주의:

- `share_plus` 최신 버전은 Flutter SDK 요구사항이 높을 수 있다.
- 현재 프로젝트 Flutter/Dart 버전과 호환되는 버전을 확인한 뒤 추가한다.
- 호환성 문제가 있으면 최신 major가 아니라 프로젝트 SDK와 맞는 lower version을 고정한다.

### 8.2 공유 URL 상수 추가

수정 후보:

```text
lib/core/config/web_links.dart
```

추가할 상수/함수:

```dart
const teenpleWebBaseUrl = 'https://teenple.app';

String teenplePostShareUrl(int postId) {
  return '$teenpleWebBaseUrl/post/$postId';
}
```

### 8.3 공유 서비스 분리

새 파일 후보:

```text
lib/core/services/share_service.dart
```

역할:

- 게시글 공유 문구 생성
- `share_plus` 호출
- 추후 링크 복사 fallback 확장 가능

예시 책임:

```dart
class ShareService {
  Future<void> sharePost({
    required int postId,
    String? title,
  }) async {
    final url = teenplePostShareUrl(postId);
    final text = title == null || title.trim().isEmpty
        ? 'TeenPle에서 게시글 보기\n$url'
        : '$title\n\nTeenPle 앱에서 보기\n$url';

    await SharePlus.instance.share(
      ShareParams(text: text),
    );
  }
}
```

### 8.4 게시글 상세 공유 버튼 연결

수정 후보:

```text
lib/features/post/pages/post_detail_page.dart
lib/features/post/pages/widgets/post_action_bar.dart
```

현재 공유 버튼은 기능 플래그 `postSharingEnabled`에 의해 숨기거나 noop 처리되어 있을 가능성이 있다.

구현 방향:

- `postSharingEnabled == false`면 기존처럼 버튼 숨김
- `postSharingEnabled == true`면 공유 버튼 표시
- 버튼 클릭 시 `ShareService.sharePost(postId: postId, title: post.title)` 호출

공유 문구에 제목을 넣을지 여부:

- 1안: 제목 포함
  - 장점: 카카오톡/문자에서 무엇을 공유했는지 알기 쉽다.
  - 단점: 제목이 외부에 노출된다.
- 2안: 제목 제외
  - 장점: 학교 인증 커뮤니티 특성과 개인정보/커뮤니티 폐쇄성에 더 안전하다.
  - 단점: 공유받는 사람이 링크 내용을 덜 이해할 수 있다.

권장:

- 초기 출시 버전은 제목 제외
- 추후 운영 정책상 문제 없다고 판단되면 제목 포함 검토

초기 문구:

```text
TeenPle에서 게시글 보기
https://teenple.app/post/{postId}
```

## 9. 딥링크 수신 구현 계획

### 9.1 dependency

권장:

```yaml
dependencies:
  app_links: <현재 Flutter SDK와 호환되는 최신 버전>
```

명령:

```powershell
flutter pub add app_links
flutter pub get
```

대안:

- Flutter/go_router의 platform deep linking만으로 처리 가능한지 먼저 확인할 수 있다.
- 다만 cold start, foreground stream, pending link 처리를 명확히 관리하려면 `app_links`가 단순하다.

### 9.2 링크 파서

새 파일:

```text
lib/core/deep_link/post_deep_link.dart
```

역할:

- `https://teenple.app/post/{id}`만 허용
- 숫자 postId만 파싱
- 이상한 URL은 무시

예시:

```dart
int? parsePostShareLink(Uri uri) {
  if (uri.scheme != 'https') return null;
  if (uri.host != 'teenple.app') return null;
  if (uri.pathSegments.length != 2) return null;
  if (uri.pathSegments[0] != 'post') return null;
  return int.tryParse(uri.pathSegments[1]);
}
```

### 9.3 딥링크 컨트롤러

새 파일 후보:

```text
lib/core/deep_link/deep_link_controller.dart
```

역할:

- 앱 시작 시 initial link 처리
- 앱 실행 중 링크 stream 처리
- postId를 파싱해 `router.go('/post/$postId')` 또는 `router.push('/post/$postId')`
- 로그인 전이면 pending postId 저장

상태별 처리:

1. 로그인된 사용자:
   - 바로 `/post/{postId}` 이동
2. 미로그인 사용자:
   - 로그인 화면 이동
   - pending postId 저장
   - 로그인 성공 후 pending postId가 있으면 게시글 상세 이동
3. 학교 인증 대기/반려 사용자:
   - 기존 인증 상태 화면으로 이동
4. 접근 불가 게시글:
   - 기존 `PostDetailPage`의 에러 UI 또는 API 예외 처리 사용

### 9.4 pending link 저장

후보:

- Riverpod `StateProvider<int?>`
- `SharedPreferences`
- `TokenStorage`와 별도 pending storage

권장:

- 1차 구현: Riverpod provider
- cold start 후 로그인까지 앱 프로세스가 유지되는 일반 흐름이면 충분하다.
- 로그인 중 앱이 죽는 경우까지 보장하려면 SharedPreferences 저장으로 확장한다.

## 10. Android App Links 설정

### 10.1 AndroidManifest

수정 파일:

```text
android/app/src/main/AndroidManifest.xml
```

`MainActivity`에 추가할 intent-filter:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="teenple.app"
        android:pathPrefix="/post" />
</intent-filter>
```

주의:

- host는 반드시 `teenple.app`이어야 한다.
- `www.teenple.app`도 사용할 계획이면 별도 host 추가가 필요하다.
- `android:autoVerify="true"`를 넣어야 자동 도메인 검증이 된다.

### 10.2 SHA-256 fingerprint 확인

Play App Signing 사용 시 `assetlinks.json`에는 Play Console의 App signing key SHA-256을 넣는다.

확인 경로:

```text
Google Play Console
→ 앱 선택
→ 테스트 및 출시 또는 설정
→ 앱 무결성(App integrity)
→ 앱 서명 키 인증서
→ SHA-256 인증서 지문
```

### 10.3 assetlinks.json

배포 경로:

```text
https://teenple.app/.well-known/assetlinks.json
```

예시:

```json
[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.teenple.teenple_frontend",
      "sha256_cert_fingerprints": [
        "PLAY_APP_SIGNING_SHA_256"
      ]
    }
  }
]
```

테스트 빌드에서도 App Links를 검증하고 싶으면 debug/release upload key fingerprint를 추가로 넣을 수 있다. 단, production 배포 파일에 어떤 fingerprint를 유지할지는 운영 기준을 정한다.

## 11. iOS Universal Links 설정

### 11.1 Associated Domains

Apple Developer에서 앱 ID의 Associated Domains capability를 활성화한다.

대상 Bundle ID:

```text
com.teenple.teenpleFrontend
```

Xcode Signing & Capabilities에 추가:

```text
applinks:teenple.app
```

확인할 entitlements 파일:

```text
ios/Runner/Runner.entitlements
ios/Runner/RunnerRelease.entitlements
```

포함되어야 할 key:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:teenple.app</string>
</array>
```

### 11.2 apple-app-site-association

배포 경로:

```text
https://teenple.app/.well-known/apple-app-site-association
```

주의:

- 확장자 `.json`을 붙이지 않는다.
- HTTPS 200으로 직접 응답해야 한다.
- redirect 되면 안 된다.
- `Content-Type`은 `application/json` 또는 Apple이 허용하는 JSON 응답이어야 한다.

예시:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": [
          "APPLE_TEAM_ID.com.teenple.teenpleFrontend"
        ],
        "components": [
          {
            "/": "/post/*",
            "comment": "Open TeenPle post detail"
          }
        ]
      }
    ]
  }
}
```

`APPLE_TEAM_ID`는 Apple Developer Membership에서 확인한다.

## 12. 웹 fallback 페이지

### 12.1 경로

공유 링크:

```text
https://teenple.app/post/{postId}
```

fallback 정적 파일:

```text
web/post/index.html
```

CloudFront 또는 hosting rewrite:

```text
/post/* -> /post/index.html
```

단, 아래 경로는 rewrite하면 안 된다.

```text
/.well-known/apple-app-site-association
/.well-known/assetlinks.json
```

### 12.2 화면 내용

게시글 내용을 보여주지 않는다.

권장 문구:

```text
TeenPle 앱에서 게시글을 확인해 주세요.
학교 인증을 완료한 고등학생만 게시글을 볼 수 있습니다.
```

버튼:

```text
App Store에서 받기
Google Play에서 받기
```

Android User-Agent:

- Google Play 버튼 강조

iOS User-Agent:

- App Store 버튼 강조

PC:

- 두 버튼 모두 표시

### 12.3 앱 열기 버튼

웹 fallback 페이지에 앱 열기 버튼을 둘 수 있다.

```text
앱에서 열기
```

동작:

- 현재 URL 그대로 유지
- 사용자가 앱이 설치된 상태에서 브라우저로 열렸다면 Universal/App Link 재시도

다만 iOS/Android 브라우저 정책상 버튼 클릭으로 항상 앱이 열리는 것은 아니다. 핵심은 최초 링크 탭에서 OS가 앱으로 보내는 것이다.

## 13. 카카오톡/인스타그램 공유 정책

### 13.1 카카오톡

초기 버전은 Kakao Developers를 사용하지 않는다.

동작:

- OS 공유창에 링크 텍스트를 전달한다.
- 사용자가 공유 대상에서 카카오톡을 선택한다.
- 카카오톡은 일반 텍스트/URL 메시지로 전송한다.

장점:

- 사업자등록 필요 없음
- Kakao SDK 설정 불필요
- 구현이 단순함
- Android/iOS 공통 흐름

단점:

- 카카오톡 전용 예쁜 카드 템플릿은 제공하지 않는다.
- 미리보기 이미지는 카카오톡이 URL의 Open Graph를 스크랩하는 방식에 의존한다.
- `/post/{id}` 페이지에 게시글 내용을 숨길 경우, 카카오톡 미리보기도 일반 서비스 안내 수준으로 표시된다.

권장:

- 초기에는 일반 링크 공유로 출시
- 추후 공유 전환율이 중요해지면 Kakao Developers 기반 템플릿 공유 검토

### 13.2 인스타그램

초기 버전은 인스타그램 전용 SDK를 사용하지 않는다.

동작:

- OS 공유창에 링크 텍스트를 전달한다.
- 인스타그램이 링크 텍스트를 받지 않거나 일부 형식을 제한할 수 있다.
- 사용자가 링크 복사를 선택한 뒤 인스타 스토리 링크 스티커에 붙여넣는 흐름도 허용한다.

주의:

- 인스타그램은 외부 앱에서 일반 URL 텍스트 공유를 항상 원하는 형태로 받아주지 않는다.
- 따라서 “인스타그램에도 반드시 링크가 예쁘게 공유된다”는 완료 기준을 잡지 않는다.
- 완료 기준은 OS 공유창에 링크를 전달하고, 링크 복사가 가능하며, 링크 자체가 정상 동작하는 것이다.

## 14. 기능 플래그 운영

현재 공유 기능 플래그:

```dart
const bool postSharingEnabled = bool.fromEnvironment(
  'POST_SHARING_ENABLED',
  defaultValue: false,
);
```

운영 전략:

1. 코드와 웹 설정을 먼저 배포한다.
2. 내부 테스트 빌드에서 아래 옵션으로 활성화한다.

```powershell
flutter build appbundle --release --dart-define=POST_SHARING_ENABLED=true
```

3. Android/iOS 링크 동작을 검증한다.
4. 문제가 없으면 프로덕션 빌드에서 `POST_SHARING_ENABLED=true`로 출시한다.

주의:

- 현재 default가 `false`이므로, 빌드 명령에 dart-define을 넣지 않으면 공유 버튼이 계속 숨겨진다.
- Play/App Store 심사 대응 문서와 실제 빌드 기능 상태가 일치해야 한다.

## 15. 구현 순서

1. URL 정책 확정
   - `https://teenple.app/post/{postId}`
2. fallback 페이지 작성
   - `web/post/index.html`
   - 게시글 내용 노출 없음
   - App Store/Google Play 버튼
3. `.well-known` 파일 작성
   - `apple-app-site-association`
   - `assetlinks.json`
4. hosting/CloudFront rewrite 설정
   - `/.well-known/*` 예외
   - `/post/* -> /post/index.html`
5. AndroidManifest App Links intent-filter 추가
6. iOS Associated Domains entitlement 추가
7. Flutter dependency 추가
   - `share_plus`
   - `app_links`
8. 공유 URL 생성 함수 추가
9. 공유 서비스 추가
10. 게시글 상세 공유 버튼 연결
11. 딥링크 파서 추가
12. 앱 시작/실행 중 딥링크 처리 추가
13. 로그인 전 pending post link 처리 추가
14. Android 실제 기기 테스트
15. iOS 실제 기기 테스트
16. `POST_SHARING_ENABLED=true` 내부 테스트 빌드 생성
17. 링크 공유 QA
18. 프로덕션 출시

## 16. QA 체크리스트

### 16.1 공유 버튼

- `POST_SHARING_ENABLED=false` 빌드에서 공유 버튼이 보이지 않는다.
- `POST_SHARING_ENABLED=true` 빌드에서 공유 버튼이 보인다.
- 공유 버튼을 누르면 OS 공유창이 열린다.
- 공유 텍스트에 `https://teenple.app/post/{postId}`가 포함된다.
- 카카오톡으로 링크 공유가 가능하다.
- 문자/메모/링크 복사로 링크 공유가 가능하다.
- 인스타그램은 OS 공유창 노출 여부와 링크 복사 가능 여부만 확인한다.

### 16.2 앱 설치 상태 딥링크

- Android에서 링크 탭 시 앱이 열린다.
- iOS에서 링크 탭 시 앱이 열린다.
- 앱이 열린 뒤 해당 게시글 상세로 이동한다.
- 앱이 이미 실행 중이어도 링크 수신 후 이동한다.
- 앱이 종료된 상태여도 링크 수신 후 이동한다.
- 이미 같은 게시글 상세 화면이면 중복 push가 발생하지 않는다.

### 16.3 앱 미설치 fallback

- Android 미설치 상태에서 링크가 브라우저로 열린다.
- iOS 미설치 상태에서 링크가 브라우저로 열린다.
- fallback 페이지가 게시글 본문을 노출하지 않는다.
- Google Play 버튼이 정상 동작한다.
- App Store 버튼이 정상 동작한다.

### 16.4 권한/예외

- 미로그인 사용자는 로그인 화면으로 이동한다.
- 로그인 후 pending post link가 있으면 게시글 상세로 이동한다.
- 학교 인증 대기 사용자는 기존 인증 대기 화면 또는 접근 제한 흐름을 따른다.
- 삭제된 게시글은 기존 오류 메시지를 보여준다.
- 숨김/차단/접근 불가 게시글은 기존 API 권한 오류를 따른다.

### 16.5 검증 파일

- `https://teenple.app/.well-known/apple-app-site-association` HTTP 200
- `https://teenple.app/.well-known/assetlinks.json` HTTP 200
- 두 파일이 redirect 없이 응답한다.
- CloudFront cache invalidation 후 최신 파일이 보인다.

## 17. Android 검증 명령

기기에서 링크 열기:

```powershell
adb shell am start -a android.intent.action.VIEW -d "https://teenple.app/post/123"
```

App Links 상태 확인:

```powershell
adb shell pm get-app-links com.teenple.teenple_frontend
```

검증 재시도:

```powershell
adb shell pm verify-app-links --re-verify com.teenple.teenple_frontend
```

## 18. iOS 검증 방법

1. Associated Domains가 포함된 빌드를 실제 기기에 설치한다.
2. 메모 앱, 문자, 카카오톡 등에 아래 링크를 입력한다.

```text
https://teenple.app/post/123
```

3. 링크를 일반 탭한다.
4. 앱이 열리는지 확인한다.
5. 게시글 상세로 이동하는지 확인한다.

문제 발생 시:

- AASA 파일 HTTP 200 여부 확인
- Team ID + Bundle ID 확인
- entitlement 포함 여부 확인
- 앱 삭제 후 재설치
- 기기 재부팅 후 재시도

## 19. 예상 리스크와 대응

### 19.1 앱 미설치 후 설치 완료 시 원 게시글 자동 이동 불가

일반 App Links/Universal Links는 앱이 설치된 경우에 강하다. 앱 미설치 → 스토어 → 설치 → 첫 실행 후 원 게시글 이동은 deferred deep link 영역이다.

초기 대응:

- 미설치자는 fallback 페이지에서 스토어로 안내한다.
- 설치 후 앱을 열면 일반 진입으로 처리한다.

추후 고도화:

- Android: Play Install Referrer API 검토
- iOS: pasteboard/Smart App Banner/딥링크 SaaS 검토
- 단, 개인정보/정책/스토어 심사 리스크 검토 필요

### 19.2 카카오톡 미리보기가 기대와 다르게 표시됨

초기에는 카카오톡 전용 템플릿을 쓰지 않으므로 미리보기 제어가 제한된다.

대응:

- fallback 페이지에 일반 Open Graph만 설정한다.
- 게시글 내용은 OG에 넣지 않는다.
- 예시 OG:

```html
<meta property="og:title" content="TeenPle에서 게시글 보기">
<meta property="og:description" content="학교 인증을 완료한 고등학생만 게시글을 확인할 수 있습니다.">
<meta property="og:image" content="https://teenple.app/assets/share-preview.png">
```

### 19.3 링크가 브라우저로 열림

원인:

- Android `assetlinks.json` SHA-256 불일치
- iOS AASA appID 불일치
- `.well-known` 파일 redirect
- 앱 entitlement 누락
- OS 캐시 문제

대응:

- 검증 파일 직접 열기
- SHA-256/Team ID 재확인
- 앱 삭제 후 재설치
- Android app links 상태 확인
- CloudFront invalidation

### 19.4 공유 기능이 심사에서 문제될 가능성

공유 기능 자체는 일반적이지만 TeenPle은 고등학생 커뮤니티이므로 외부 공개 범위를 명확히 해야 한다.

대응:

- 외부 웹에 게시글 내용 비노출
- 앱 내부에서 학교 인증/로그인/권한 검사 유지
- 스토어 심사 메모에 필요 시 “공유 링크는 앱 진입/다운로드 안내이며, 게시글 내용은 인증된 앱 사용자만 확인 가능”이라고 설명

## 20. 출시 전략

1차 출시:

- OS 기본 공유창
- App Links/Universal Links
- 앱 미설치 fallback
- 게시글 내용 비노출
- Kakao/Instagram 전용 SDK 없음

2차 고도화:

- 카카오톡 공유 템플릿 검토
- 공유 랜딩 페이지 디자인 개선
- OG 이미지 추가
- 공유 클릭 분석
- Android deferred deep link 검토

3차 고도화:

- 게시글별 안전한 미리보기 정책 검토
- 신고/삭제된 게시글 링크 처리 UX 개선
- 친구 초대/학교 초대 링크와 통합

## 21. 완료 기준

아래 조건을 모두 만족하면 공유 기능 1차 구현 완료로 본다.

- 앱에서 공유 버튼이 기능 플래그에 따라 노출된다.
- 공유 버튼 클릭 시 OS 공유창이 열린다.
- 공유 링크 형식이 `https://teenple.app/post/{postId}`이다.
- 카카오톡에 일반 링크 공유가 가능하다.
- 링크 복사가 가능하다.
- 앱 설치자는 링크 클릭 시 앱의 해당 게시글 상세로 이동한다.
- 앱 미설치자는 fallback 페이지로 이동한다.
- fallback 페이지는 게시글 내용을 노출하지 않는다.
- Android App Links 검증이 통과된다.
- iOS Universal Links 검증이 통과된다.
- 미로그인/미인증/접근 불가 상태에서 기존 보안 정책이 우회되지 않는다.

## 22. 참고 문서

- Firebase Dynamic Links 종료 FAQ: https://firebase.google.com/support/dynamic-links-faq
- Firebase App Links/Universal Links migration guide: https://firebase.google.com/support/guides/app-links-universal-links
- Android App Links: https://developer.android.com/training/app-links
- Android 공유 인텐트: https://developer.android.com/training/sharing/send
- Android Install Referrer API: https://developer.android.com/google/play/installreferrer
- Apple Universal Links: https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content
- Kakao Talk Share 개념: https://developers.kakao.com/docs/ko/kakaotalk-share/common
- share_plus: https://pub.dev/packages/share_plus

