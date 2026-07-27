# TeenPle 게시글 공유 기능 구현 현황

작성일: 2026-07-26

## 1. 이번 작업 목표

게시글 상세 페이지에 남아 있던 기존 공유 버튼 코드를 살려서, 사용자가 버튼을 누르면 OS 기본 공유 시트가 열리고 다음 형식의 링크가 공유되도록 구현한다.

```text
https://teenple.app/post/{postId}
```

앱이 설치된 사용자는 해당 링크를 눌렀을 때 TeenPle 앱의 게시글 상세 화면으로 이동하고, 앱이 설치되지 않은 사용자는 웹 fallback 페이지를 보도록 준비한다.

## 2. 완료된 코드 작업

### 2.1 공유 버튼 UI 재사용

기존 파일:

```text
lib/features/post/pages/widgets/post_action_bar.dart
```

공유 버튼은 이미 북마크 버튼 오른쪽에 남아 있었다.

노출 조건:

```dart
if (postSharingEnabled) ...
```

현재 실서비스 기준으로 공유 기능은 기본 활성화되어 있다.

```text
POST_SHARING_ENABLED defaultValue: true
```

문제가 생겼을 때만 빌드 시 아래 플래그로 끌 수 있다.

```powershell
--dart-define=POST_SHARING_ENABLED=false
```

### 2.2 공유 링크 config 추가

추가 파일:

```text
lib/core/config/share_links.dart
```

역할:

- TeenPle 웹 기본 도메인 관리
- 게시글 공유 URL 생성

현재 공유 URL 형식:

```text
https://teenple.app/post/{postId}
```

### 2.3 공유 서비스 추가

추가 파일:

```text
lib/core/services/share_service.dart
```

역할:

- `share_plus`를 이용해 OS 기본 공유 시트 호출
- 게시글 제목과 공유 링크를 함께 공유

공유 문구 형식:

```text
TeenPle에서 게시글을 확인해보세요.
https://teenple.app/post/{postId}
```

게시글 제목/본문/작성자/댓글은 외부 공유 문구에 넣지 않는다. 학교 인증 커뮤니티 게시글 내용이 카카오톡, 문자, SNS 미리보기로 노출되지 않게 하기 위한 정책이다.

### 2.4 게시글 상세 페이지 연결

수정 파일:

```text
lib/features/post/pages/post_detail_page.dart
```

기존 상태:

```dart
onShareTap: () {},
```

현재 상태:

- `ShareService.sharePost(...)` 호출
- 공유 실패 시 스낵바 표시

### 2.5 패키지 추가

수정 파일:

```text
pubspec.yaml
```

추가:

```yaml
share_plus: ^10.1.4
```

## 3. 완료된 딥링크 준비 작업

### 3.1 Android App Links intent-filter 추가

수정 파일:

```text
android/app/src/main/AndroidManifest.xml
```

추가된 링크 범위:

```text
https://teenple.app/post...
```

의도:

- `https://teenple.app/post/{postId}` 링크를 Android에서 TeenPle 앱으로 열기
- 다른 웹 문서 `/privacy`, `/terms`, `/support` 등은 앱이 가로채지 않도록 `/post` 경로만 제한

### 3.2 Android assetlinks.json 추가

추가 파일:

```text
web/.well-known/assetlinks.json
```

현재 포함된 값:

- package name: `com.teenple.teenple_frontend`
- SHA-256: release upload keystore 기준으로 계산한 값

주의:

- Google Play App Signing을 사용하는 경우, 최종 검증에는 Play Console의 **App signing key certificate SHA-256**이 필요할 수 있다.
- 현재 파일의 SHA-256이 Play Console의 앱 서명 인증서와 일치하는지 반드시 확인해야 한다.

### 3.3 iOS Universal Links entitlement 추가

수정 파일:

```text
ios/Runner/Runner.entitlements
ios/Runner/RunnerRelease.entitlements
```

추가:

```text
applinks:teenple.app
```

### 3.4 Apple AASA 파일 추가

추가 파일:

```text
web/.well-known/apple-app-site-association
```

현재 appID:

```text
2HT77KJAY2.com.teenple.teenpleFrontend
```

확인 필요:

- Apple Team ID가 `2HT77KJAY2`인지
- iOS Bundle ID가 `com.teenple.teenpleFrontend`인지
- Apple Developer의 App ID에 Associated Domains capability가 켜져 있는지

### 3.5 앱 미설치 fallback 페이지 추가

추가 파일:

```text
web/post/index.html
```

역할:

- 앱이 설치되어 있지 않은 사용자가 공유 링크를 눌렀을 때 보여줄 안내 페이지
- 게시글 본문/댓글/작성자 정보는 웹에 공개하지 않음
- Google Play/App Store 이동 버튼 제공

현재 App Store 링크:

```text
https://apps.apple.com/app/id6784217699
```

## 4. 아직 운영자가 해야 하는 작업

### 4.1 웹 파일 AWS 배포

다음 파일들을 `teenple.app` 정적 웹 배포에 포함해야 한다.

```text
web/.well-known/assetlinks.json
web/.well-known/apple-app-site-association
web/post/index.html
```

배포 후 반드시 아래 URL이 HTTPS 200으로 열려야 한다.

```text
https://teenple.app/.well-known/assetlinks.json
https://teenple.app/.well-known/apple-app-site-association
```

### 4.2 CloudFront Function 수정

현재 정적 웹 구조에서는 `/post/123` 요청이 자동으로 `web/post/index.html`로 가지 않을 수 있다.

CloudFront Function에 다음 규칙이 필요하다.

```js
if (uri.startsWith('/post/')) {
  request.uri = '/post/index.html';
  return request;
}
```

이 규칙은 기존 clean URL rewrite보다 먼저 실행되어야 한다.

배포 후 아래 URL을 확인한다.

```text
https://teenple.app/post/1
```

정상 기대:

- HTTP 200
- 게시글 본문 노출 없음
- 앱 설치/스토어 이동 안내 페이지 표시

### 4.3 CloudFront 캐시 무효화

배포 후 invalidation 필요:

```text
/.well-known/*
/post*
```

또는 전체 무효화:

```text
/*
```

### 4.4 App Store URL 확인

파일:

```text
web/post/index.html
```

현재 URL:

```text
https://apps.apple.com/app/id6784217699
```

App Store Connect의 실제 TeenPle 앱 URL과 동일한지 출시 전 한 번 더 확인한다.

### 4.5 Android SHA-256 확인

Play Console에서 확인:

```text
Setup > App integrity > App signing key certificate > SHA-256
```

이 값이 아래 파일과 일치해야 한다.

```text
web/.well-known/assetlinks.json
```

일치하지 않으면 `assetlinks.json`에 Play App Signing SHA-256을 추가해야 한다.

### 4.6 Apple Developer capability 확인

Apple Developer에서 확인:

- Identifiers
- TeenPle App ID
- Associated Domains 활성화

활성화 후 provisioning profile을 다시 갱신해야 할 수 있다.

## 5. 빌드 플래그

공유 기능은 기본 활성화되어 있으므로 일반 빌드에도 공유 버튼이 포함된다.

공유 기능만 명시적으로 켠 빌드:

```powershell
flutter build appbundle --release `
  --dart-define=POST_SHARING_ENABLED=true
```

긴급하게 공유 기능을 끄는 빌드:

```powershell
flutter build appbundle --release `
  --dart-define=POST_SHARING_ENABLED=false
```

광고와 공유를 함께 켜는 Android 빌드 예시:

```powershell
flutter build appbundle --release `
  --dart-define=POST_SHARING_ENABLED=true `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=PARTNER_ADS_ENABLED=false `
  --dart-define=ADMOB_ANDROID_HOME_FEED_BANNER_UNIT_ID=ca-app-pub-.../... `
  --dart-define=ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-.../...
```

## 6. 검증 체크리스트

로컬/기기:

- [ ] `flutter pub get` 성공
- [ ] `flutter analyze` 성공
- [ ] `POST_SHARING_ENABLED=false`에서 공유 버튼 숨김
- [ ] `POST_SHARING_ENABLED=true`에서 북마크 오른쪽 공유 버튼 표시
- [ ] 공유 버튼 탭 시 OS 공유 시트 표시
- [ ] 공유 문구에 `https://teenple.app/post/{postId}` 포함

Android:

- [ ] `https://teenple.app/.well-known/assetlinks.json` HTTP 200
- [ ] 앱 설치 후 공유 링크 클릭 시 TeenPle 앱 열림
- [ ] `adb shell pm get-app-links com.teenple.teenple_frontend`로 검증 상태 확인

iOS:

- [ ] `https://teenple.app/.well-known/apple-app-site-association` HTTP 200
- [ ] 앱 설치 후 공유 링크 클릭 시 TeenPle 앱 열림
- [ ] Associated Domains capability 활성화 확인

웹 fallback:

- [ ] `https://teenple.app/post/1` HTTP 200
- [ ] 게시글 본문/댓글/작성자 정보가 웹에 노출되지 않음
- [ ] Google Play 버튼 정상
- [ ] App Store 버튼 실제 URL로 교체 완료

## 7. 현재 남은 리스크

- App Store URL `https://apps.apple.com/app/id6784217699`가 실제 TeenPle 앱 URL과 일치하는지 최종 확인이 필요하다.
- Android `assetlinks.json`의 SHA-256이 Play App Signing 인증서와 다를 수 있다.
- CloudFront Function을 수정하지 않으면 `/post/{postId}` fallback이 403/404가 날 수 있다.
- iOS provisioning profile이 Associated Domains 추가 이후 갱신되지 않으면 빌드 또는 Universal Links 동작에 문제가 생길 수 있다.

## 8. 실서비스 기준 최종 정리

이번 추가 점검에서 보완한 부분:

- 공유 기능 기본값을 `true`로 변경했다.
- 따라서 일반 프로덕션 빌드에서도 공유 버튼이 기본 노출된다.
- 문제가 생긴 경우에만 `--dart-define=POST_SHARING_ENABLED=false`로 공유 기능을 끌 수 있다.
- 외부 공유 문구에서 게시글 제목을 제거했다.
- 공유 문구에는 게시글 제목, 본문, 작성자, 댓글을 넣지 않는다.
- Android App Links pathPrefix를 `/post/`로 좁혔다.
- `/posters`, `/post-anything` 같은 의도하지 않은 경로를 앱이 가로채지 않도록 하기 위함이다.
- AndroidManifest에 `flutter_deeplinking_enabled=true`를 명시했다.
- Info.plist에 `FlutterDeepLinkingEnabled=true`를 명시했다.

현재 실서비스 공유 문구:

```text
TeenPle에서 게시글을 확인해보세요.
https://teenple.app/post/{postId}
```

공유 기능을 포함한 기본 출시 빌드:

```powershell
flutter build appbundle --release
```

공유 기능을 명시적으로 끄는 긴급 빌드:

```powershell
flutter build appbundle --release `
  --dart-define=POST_SHARING_ENABLED=false
```

광고와 공유를 함께 켜는 출시 빌드 예시:

```powershell
flutter build appbundle --release `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=PARTNER_ADS_ENABLED=false `
  --dart-define=ADMOB_ANDROID_HOME_FEED_BANNER_UNIT_ID=ca-app-pub-.../... `
  --dart-define=ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-.../...
```

검증에서 반드시 볼 것:

- 공유 버튼이 북마크 오른쪽에 보이는지
- 공유 버튼 탭 시 OS 공유 시트가 열리는지
- 공유 텍스트에 게시글 제목/본문이 포함되지 않는지
- 공유 링크가 `https://teenple.app/post/{postId}`인지
- 앱 설치 상태에서 링크 클릭 시 `/post/:postId` 화면으로 이동하는지
- 앱 미설치 상태에서 링크 클릭 시 fallback 페이지가 열리는지
