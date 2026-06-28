# 게시글 공유 딥링크 구현 계획

목표는 웹에서 게시글 내용을 보여주지 않고, 공유받은 URL을 눌렀을 때 앱이 설치되어 있으면 TeenPle 앱의 해당 게시글 상세로 이동시키는 것이다. 앱이 설치되어 있지 않으면 같은 URL이 웹 fallback 페이지로 열리고, 사용자를 App Store 또는 Play Store 설치 링크로 안내한다.

## 0. 최종 사용자 흐름

공유 버튼을 누르면 앱이 아래 URL을 공유한다.

```text
https://teenple.app/post/{postId}
```

예시:

```text
https://teenple.app/post/123
```

동작:

1. 앱 설치됨
   - iOS: Universal Links로 앱이 열린다.
   - Android: App Links로 앱이 열린다.
   - 앱은 `/post/123`을 읽고 기존 `PostDetailPage(postId: 123)`로 이동한다.
2. 앱 미설치
   - 브라우저에서 `https://teenple.app/post/123`이 열린다.
   - 게시글 내용은 노출하지 않는다.
   - "앱에서 게시글을 확인해 주세요" 안내와 스토어 설치 버튼을 보여준다.
   - 가능하면 OS를 감지해 iOS는 App Store, Android는 Play Store로 보낸다.

## 1. 현재 프로젝트 기준 확인값

현재 FE 프로젝트에서 확인된 값:

```text
도메인: teenple.app
iOS Bundle ID: com.teenple.teenpleFrontend
Android applicationId: com.teenple.teenple_frontend
앱 내부 게시글 상세 라우트: /post/:postId
```

현재 없는 것:

```text
share_plus dependency
app_links 또는 deep link 수신용 dependency
iOS Associated Domains entitlement
Android App Links intent-filter
/.well-known/apple-app-site-association
/.well-known/assetlinks.json
/post/{postId} 웹 fallback 페이지
```

## 2. URL 정책 결정

권장 URL:

```text
https://teenple.app/post/{postId}
```

이유:

- 현재 앱 라우터가 이미 `/post/:postId`를 사용한다.
- 딥링크 수신 후 별도 변환 없이 기존 라우트로 보낼 수 있다.
- 웹 fallback도 `/post/123` 경로만 처리하면 된다.

주의:

- 웹에서는 게시글 상세 HTML을 만들지 않는다.
- `/post/{id}` fallback 페이지에는 게시글 제목, 본문, 작성자, 댓글 수 등을 넣지 않는다.
- 미로그인 사용자에게도 게시글 내용을 웹에서 보여주지 않는다.

## 3. iOS Universal Links 설정

### 3.1 Apple Developer에서 Associated Domains 켜기

브라우저에서 Apple Developer에 접속한다.

```text
https://developer.apple.com/account
```

클릭 순서:

1. 로그인
2. `Certificates, IDs & Profiles` 클릭
3. 왼쪽 메뉴에서 `Identifiers` 클릭
4. 목록에서 앱 Identifier 선택
   - `com.teenple.teenpleFrontend`
5. `Capabilities` 또는 `Additional Capabilities` 영역에서 `Associated Domains` 체크
6. 우측 상단 `Save` 클릭

확인할 것:

- App ID에 `Associated Domains`가 활성화되어야 한다.
- 저장 후 provisioning profile이 갱신되어야 한다.

### 3.2 Xcode에서 Associated Domains 추가

macOS에서 `ios/Runner.xcworkspace`를 연다.

클릭 순서:

1. Xcode 실행
2. `ios/Runner.xcworkspace` 열기
3. 왼쪽 Project Navigator에서 `Runner` 프로젝트 클릭
4. TARGETS에서 `Runner` 선택
5. 상단 탭 `Signing & Capabilities` 클릭
6. 좌측 상단 `+ Capability` 클릭
7. 검색창에 `Associated Domains` 입력
8. `Associated Domains` 더블클릭
9. 추가된 Associated Domains 영역에서 `+` 클릭
10. 아래 값을 입력

```text
applinks:teenple.app
```

확인할 것:

- Debug와 Release 모두 같은 Associated Domains가 들어가야 한다.
- 이 프로젝트에는 entitlements 파일이 2개 있다.

```text
ios/Runner/Runner.entitlements
ios/Runner/RunnerRelease.entitlements
```

두 파일 모두 최종적으로 아래 key를 포함해야 한다.

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:teenple.app</string>
</array>
```

### 3.3 apple-app-site-association 파일 만들기

웹 루트에 아래 경로로 파일을 배포한다.

```text
https://teenple.app/.well-known/apple-app-site-association
```

중요:

- 파일명에 `.json` 확장자를 붙이면 안 된다.
- HTTPS여야 한다.
- redirect가 있으면 안 된다.
- 인증서가 유효해야 한다.
- 응답은 JSON이어야 한다.

파일 내용 예시:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": [
          "{APPLE_TEAM_ID}.com.teenple.teenpleFrontend"
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

`{APPLE_TEAM_ID}`는 Apple Developer Team ID로 바꾼다.

Team ID 확인 위치:

1. Apple Developer 접속
2. 우측 상단 계정 이름 클릭
3. `Membership details` 클릭
4. `Team ID` 확인

구버전 호환이 필요하면 `paths` 방식도 사용할 수 있다.

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "{APPLE_TEAM_ID}.com.teenple.teenpleFrontend",
        "paths": [
          "/post/*"
        ]
      }
    ]
  }
}
```

둘 중 하나만 쓰기보다, iOS 호환성을 넓게 잡으려면 `components` 기반을 우선 사용하고 QA에서 문제가 있으면 `paths` 기반으로 단순화한다.

## 4. Android App Links 설정

### 4.1 AndroidManifest intent-filter 추가

수정 파일:

```text
android/app/src/main/AndroidManifest.xml
```

`MainActivity` 안에 기존 launcher intent-filter 아래로 App Links intent-filter를 추가한다.

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

- `android:autoVerify="true"`가 있어야 Android가 도메인 검증을 시도한다.
- `android:host="teenple.app"`와 웹의 `assetlinks.json` 도메인이 정확히 같아야 한다.
- `android:pathPrefix="/post"`는 `/post/123`을 포함한다.

### 4.2 Play Console에서 SHA-256 확인

Play App Signing을 쓰는 경우, `assetlinks.json`에는 보통 업로드 키가 아니라 앱 서명 키의 SHA-256이 필요하다.

클릭 순서:

1. Google Play Console 접속
2. 앱 선택
3. 왼쪽 메뉴 `Setup` 클릭
4. `App integrity` 클릭
5. `App signing` 탭 확인
6. `App signing key certificate` 영역 찾기
7. `SHA-256 certificate fingerprint` 복사

필요하면 같은 화면에서 `Upload key certificate`의 SHA-256도 따로 기록한다. 실제 App Links 검증에는 배포되는 APK/AAB를 서명하는 인증서의 fingerprint가 맞아야 한다.

### 4.3 assetlinks.json 파일 만들기

웹 루트에 아래 경로로 파일을 배포한다.

```text
https://teenple.app/.well-known/assetlinks.json
```

파일 내용 예시:

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
        "AA:BB:CC:DD:..."
      ]
    }
  }
]
```

`AA:BB:CC:DD:...`는 Play Console에서 복사한 SHA-256 fingerprint로 바꾼다.

Debug 빌드에서도 테스트하려면 debug keystore SHA-256을 추가로 넣을 수 있다. 단, production 파일에 debug fingerprint를 계속 남길지는 보안 정책에 따라 결정한다.

## 5. AWS/CloudFront 배포 작업

현재 `teenple.app`은 정적 페이지와 API 용도로 쓰고 있으므로, 아래 파일과 fallback 페이지를 추가하면 된다.

필요 경로:

```text
/.well-known/apple-app-site-association
/.well-known/assetlinks.json
/post/{postId}
```

### 5.1 정적 파일 위치

FE repo의 웹 정적 산출물에 아래 구조가 들어가야 한다.

```text
web/
  .well-known/
    apple-app-site-association
    assetlinks.json
  post/
    index.html
```

단, `/post/123`처럼 동적 ID가 붙는 경로는 S3에 실제 `post/123/index.html`을 만들 수 없으므로 CloudFront rewrite가 필요하다.

권장 rewrite:

```text
/post/* -> /post/index.html
/.well-known/apple-app-site-association -> 그대로
/.well-known/assetlinks.json -> 그대로
```

### 5.2 CloudFront Function 수정

AWS Console에서:

1. `CloudFront` 이동
2. 왼쪽 메뉴 `Functions` 클릭
3. 현재 `teenple.app` distribution에 연결된 viewer request function 선택
4. `Build` 탭 클릭
5. 함수 코드에 `/post/` rewrite 추가
6. `Save changes`
7. `Publish` 클릭
8. Distribution의 `Behaviors`에서 viewer request function 연결 확인

rewrite 예시:

```js
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.startsWith('/.well-known/')) {
    return request;
  }

  if (uri === '/post' || uri.startsWith('/post/')) {
    request.uri = '/post/index.html';
    return request;
  }

  if (!uri.includes('.') && !uri.endsWith('/')) {
    request.uri = uri + '/index.html';
    return request;
  }

  if (uri.endsWith('/')) {
    request.uri = uri + 'index.html';
  }

  return request;
}
```

주의:

- `/.well-known/*`는 절대 `/index.html`로 rewrite하면 안 된다.
- Apple과 Android 검증 파일은 정확한 경로에서 직접 열려야 한다.

### 5.3 CloudFront 캐시 무효화

파일 업로드 후:

1. CloudFront 이동
2. Distribution 선택
3. `Invalidations` 탭 클릭
4. `Create invalidation` 클릭
5. 아래 경로 입력

```text
/.well-known/apple-app-site-association
/.well-known/assetlinks.json
/post/*
```

6. `Create invalidation` 클릭

## 6. 웹 fallback 페이지

`/post/{postId}`가 웹에서 열렸을 때 게시글 내용 대신 설치 안내만 보여준다.

페이지 문구 예시:

```text
TeenPle 앱에서 게시글을 확인해 주세요.
학교 커뮤니티 게시글은 앱에서만 볼 수 있습니다.
```

버튼:

```text
App Store에서 받기
Google Play에서 받기
```

자동 리다이렉트 정책:

- iPhone/iPad User-Agent면 App Store 또는 TestFlight 링크로 이동
- Android User-Agent면 Play Store 링크로 이동
- PC면 두 버튼을 모두 보여줌

초기 TestFlight 단계:

```text
iOS fallback: TestFlight public link 또는 앱 출시 안내 페이지
Android fallback: Play Store 내부/공개 테스트 링크 또는 출시 안내 페이지
```

정식 출시 후:

```text
iOS fallback: https://apps.apple.com/app/id{APP_STORE_ID}
Android fallback: https://play.google.com/store/apps/details?id=com.teenple.teenple_frontend
```

## 7. Flutter dependency 추가

필요 dependency:

```yaml
dependencies:
  share_plus: ^10.1.4
  app_links: ^6.3.3
```

버전은 적용 시점에 최신 호환 버전으로 확인한다.

명령:

```powershell
flutter pub add share_plus
flutter pub add app_links
flutter pub get
```

역할:

- `share_plus`: OS 공유 시트 열기
- `app_links`: 앱 실행 중/종료 상태에서 들어온 Universal Link/App Link 수신

## 8. Flutter 딥링크 처리 설계

### 8.1 링크 파서

새 파일 예시:

```text
lib/core/deep_link/post_deep_link.dart
```

역할:

- URI가 `teenple.app`인지 확인
- path가 `/post/{id}`인지 확인
- `{id}`가 int인지 확인
- 유효하면 postId 반환

예시:

```dart
int? parseSharedPostId(Uri uri) {
  if (uri.scheme != 'https') return null;
  if (uri.host != 'teenple.app') return null;

  final segments = uri.pathSegments;
  if (segments.length != 2) return null;
  if (segments[0] != 'post') return null;

  return int.tryParse(segments[1]);
}
```

### 8.2 앱 시작 시 링크 처리

앱 시작 시:

1. `AppLinks().getInitialLink()` 호출
2. postId 파싱
3. 로그인 세션이 있으면 `/post/{postId}`로 이동
4. 로그인 세션이 없으면 로그인 이후 이동할 pending link로 저장

주의:

- 학교 인증 대기/반려 상태 사용자는 게시글 상세 접근이 막힐 수 있다.
- 이 경우 기존 라우팅 정책에 맞춰 인증 대기/반려 화면으로 보내야 한다.

### 8.3 앱 실행 중 링크 처리

앱 실행 중:

1. `AppLinks().uriLinkStream.listen(...)`
2. postId 파싱
3. 현재 페이지와 무관하게 `router.push('/post/$postId')`
4. 이미 같은 게시글 상세에 있으면 중복 push하지 않도록 방어

### 8.4 라우터 연결

현재 이미 아래 라우트가 있다.

```dart
GoRoute(
  path: '/post/:postId',
  builder: (context, state) {
    final postId = int.parse(state.pathParameters['postId']!);
    return PostDetailPage(postId: postId);
  },
),
```

딥링크 수신 시 이 라우트를 그대로 사용한다.

## 9. 공유 버튼 구현

현재 `PostActionBar`에 공유 버튼이 있고, `PostDetailPage`에서 `onShareTap: () {}`로 비어 있다.

수정 위치:

```text
lib/features/post/pages/post_detail_page.dart
```

공유 URL 생성:

```dart
final shareUrl = Uri.https('teenple.app', '/post/${post.postId}').toString();
```

공유 문구 예시:

```dart
final text = '${post.title}\n\nTeenPle 앱에서 보기\n$shareUrl';
```

구현 예시:

```dart
onShareTap: () {
  final url = Uri.https('teenple.app', '/post/${post.postId}').toString();
  Share.share('${post.title}\n\nTeenPle 앱에서 보기\n$url');
},
```

주의:

- 공유 텍스트에 게시글 본문을 길게 넣지 않는다.
- 익명 게시판 성격을 고려해 작성자 정보는 공유하지 않는다.
- 신고/차단/삭제된 게시글 링크를 눌렀을 때는 앱 내부 기존 오류 처리에 맡긴다.

## 10. 로그인/권한 상태 처리

공유 링크로 앱을 열었을 때 가능한 상태:

1. 정상 로그인 + 학교 인증 완료
   - 게시글 상세로 이동
2. 미로그인
   - 로그인 화면으로 이동
   - 로그인 성공 후 pending post link가 있으면 게시글 상세로 이동
3. 학교 인증 대기
   - 인증 대기 화면으로 이동
4. 학교 인증 반려
   - 인증 반려 화면으로 이동
5. 게시글 삭제됨 또는 접근 불가
   - 게시글 상세 화면의 기존 error UI 표시

pending link 저장 위치 후보:

```text
Riverpod StateProvider<Uri?>
또는 SharedPreferences
```

앱이 cold start로 열리고 로그인 화면을 거칠 수 있으므로, 단순 메모리 provider만으로 충분한지 테스트가 필요하다. 앱 프로세스가 유지되는 일반 로그인 흐름이면 provider로 충분하다.

## 11. iOS 테스트 절차

### 11.1 파일 검증

브라우저 또는 터미널에서 확인:

```powershell
curl https://teenple.app/.well-known/apple-app-site-association
```

확인:

- HTTP 200
- redirect 없음
- JSON 내용 정상
- Team ID와 Bundle ID 정확
- `/post/*` 포함

### 11.2 실제 기기 테스트

iOS Universal Links는 시뮬레이터보다 실제 기기 테스트를 권장한다.

테스트 순서:

1. Associated Domains가 들어간 빌드를 TestFlight 또는 직접 설치
2. Notes 앱 또는 카카오톡/문자에 아래 링크 입력

```text
https://teenple.app/post/123
```

3. 링크를 길게 누르지 말고 일반 탭
4. 앱이 열리는지 확인
5. 해당 게시글 상세로 이동하는지 확인

문제 상황:

- Safari에서만 열림
  - AASA 파일 문제 가능성
  - Associated Domains entitlement 누락 가능성
  - 앱 설치 후 AASA 캐시가 갱신되지 않았을 가능성

대응:

1. 앱 삭제
2. 기기 재부팅
3. 앱 재설치
4. 다시 링크 탭

## 12. Android 테스트 절차

### 12.1 파일 검증

```powershell
curl https://teenple.app/.well-known/assetlinks.json
```

확인:

- HTTP 200
- redirect 없음
- JSON array 형식
- package name 정확
- SHA-256 정확

### 12.2 adb로 링크 열기

Android 기기가 연결된 상태에서:

```powershell
adb shell am start -a android.intent.action.VIEW -d "https://teenple.app/post/123"
```

확인:

- 앱이 열리는지
- 게시글 상세로 이동하는지

### 12.3 App Links 검증 상태 확인

Android 12 이상:

```powershell
adb shell pm get-app-links com.teenple.teenple_frontend
```

필요 시 검증 재시도:

```powershell
adb shell pm verify-app-links --re-verify com.teenple.teenple_frontend
```

문제 상황:

- 브라우저 선택창이 뜸
  - assetlinks 검증 실패 가능성
  - SHA-256 불일치 가능성
  - autoVerify intent-filter 누락 가능성

## 13. Play Console/App Store 출시 전 작업

### 13.1 App Store 링크 확보

App Store Connect에서:

1. `My Apps` 클릭
2. TeenPle 앱 선택
3. `App Information` 또는 앱 기본 정보 화면으로 이동
4. Apple ID 또는 App Store URL 확인

정식 URL 형식:

```text
https://apps.apple.com/app/id{APP_STORE_ID}
```

출시 전에는 TestFlight public link를 fallback으로 사용할 수 있다.

### 13.2 Play Store 링크 확보

형식:

```text
https://play.google.com/store/apps/details?id=com.teenple.teenple_frontend
```

내부 테스트/비공개 테스트 단계에서는 일부 사용자에게만 열릴 수 있다.

## 14. 구현 순서 권장안

1. 공유 URL 정책 확정
   - `https://teenple.app/post/{postId}` 사용
2. 웹 fallback 페이지 작성
   - 게시글 내용 노출 없음
   - 앱 설치 안내만 표시
3. AASA와 assetlinks 파일 작성
4. CloudFront rewrite 수정
   - `/.well-known/*` 예외
   - `/post/* -> /post/index.html`
5. iOS Associated Domains 설정
6. Android Manifest App Links 설정
7. Flutter dependency 추가
   - `share_plus`
   - `app_links`
8. 앱 딥링크 수신 처리 구현
9. 게시글 상세 공유 버튼 구현
10. 실제 iOS 기기 테스트
11. 실제 Android 기기 또는 Play signed build 테스트
12. fallback 스토어 링크를 정식 링크로 교체

## 15. 완료 기준

기능 완료로 판단하려면 아래가 모두 통과해야 한다.

- iOS에서 `https://teenple.app/post/{id}` 탭 시 앱이 열린다.
- Android에서 `https://teenple.app/post/{id}` 탭 시 앱이 열린다.
- 앱이 열린 뒤 해당 게시글 상세로 이동한다.
- 앱 미설치 시 웹 fallback 페이지가 열린다.
- 웹 fallback에서 게시글 내용이 보이지 않는다.
- fallback에서 App Store/Play Store로 이동할 수 있다.
- 공유 버튼이 OS 공유 시트를 연다.
- 공유 텍스트에 올바른 post URL이 포함된다.
- 삭제/비공개/차단된 게시글 링크는 앱 내부에서 기존 오류 처리된다.

## 16. 참고 공식 문서

- Apple Associated Domains: https://developer.apple.com/documentation/xcode/supporting-associated-domains
- Apple Universal Links: https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content
- Android App Links: https://developer.android.com/training/app-links
- Android Digital Asset Links: https://developers.google.com/digital-asset-links
- Flutter deep linking: https://docs.flutter.dev/ui/navigation/deep-linking
- go_router: https://pub.dev/packages/go_router
- app_links: https://pub.dev/packages/app_links
- share_plus: https://pub.dev/packages/share_plus
