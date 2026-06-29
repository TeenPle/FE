# Google Play 출시 제출 상세 가이드

Last reviewed: 2026-06-29

이 문서는 TeenPle Android 앱을 Google Play에 제출할 때 위에서부터 그대로 따라 하기 위한 상세 절차다.

현재 코드 확인 결과:

- FE `flutter analyze`: 통과
- BE `.\gradlew.bat compileJava`: 통과
- 기본 API: `https://api.teenple.app`
- 광고: 기본 비활성화, `google_mobile_ads`/AdMob/test ad 문자열 없음
- 공유 기능: 기본 비활성화, `POST_SHARING_ENABLED=false`
- Android release manifest: `android:usesCleartextTraffic="false"`
- Flutter SDK 기본 Android SDK: `compileSdk 36`, `targetSdk 36`
- 릴리스 서명 파일: 아직 없음
  - `FE/android/key.properties`: 없음
  - `FE/android/upload-keystore.jks`: 없음
  - 이 상태에서는 `flutter build appbundle --release`가 실패한다.

중요 원칙:

- Play 심사 빌드에는 아직 준비 중인 기능을 노출하지 않는다.
- 이번 심사 빌드는 광고 없음으로 제출한다.
- 이번 심사 빌드는 공유 버튼 숨김 상태로 제출한다.
- 심사자가 회원가입/학교 인증 대기 상태에 막히지 않도록 검증 완료 계정을 제공한다.
- 코드, Play Console 입력, 개인정보처리방침, Data safety 답변은 서로 일치해야 한다.

## 1. 제출 전 로컬 상태 정리

PowerShell에서 FE 저장소로 이동한다.

```powershell
cd C:\develop\FE
```

현재 브랜치와 변경 상태를 확인한다.

```powershell
git status --short --branch
```

정상 상태:

```text
## main...origin/main
```

주의:

- `M`으로 시작하는 변경 파일이 있으면 먼저 확인한다.
- 출시 빌드는 `main` 기준으로 만든다.
- 의도하지 않은 로컬 변경이 있으면 제출 빌드 전에 정리한다.

최신 코드를 받는다.

```powershell
git switch main
git fetch origin
git pull origin main
```

BE도 상태를 확인한다.

```powershell
cd C:\develop\BE\backend
git status --short --branch
```

정상 상태:

```text
## develop...origin/develop
```

운영 서버가 이미 배포된 코드와 맞는지 별도로 확인한다. Play 심사 중에는 API 서버를 재시작하거나 DB를 초기화하지 않는다.

## 2. FE 코드 검증

FE로 이동한다.

```powershell
cd C:\develop\FE
```

의존성과 정적 분석을 확인한다.

```powershell
flutter pub get
flutter analyze
```

정상 결과:

```text
No issues found!
```

아래 문자열이 나오지 않아야 한다.

```powershell
rg -n "google_mobile_ads|AdMob|ca-app-pub|test ad|TestAd" lib android ios pubspec.yaml web
rg -n "POST_SHARING_ENABLED=true|ADS_ENABLED=true|API_BASE_URL=http|notion|Notion|www\.notion\.so" lib android ios pubspec.yaml web
```

정상 결과:

- 광고 SDK, AdMob ID, test ad 문자열 없음
- `POST_SHARING_ENABLED=true` 없음
- `ADS_ENABLED=true` 없음
- 로컬 API URL 없음
- Notion 링크 없음

현재 확인해야 할 핵심 파일:

- `lib/core/network/base_url.dart`
  - 기본값이 `https://api.teenple.app`이어야 한다.
- `lib/core/config/feature_flags.dart`
  - `ADS_ENABLED` 기본값이 `false`여야 한다.
  - `POST_SHARING_ENABLED` 기본값이 `false`여야 한다.
- `android/app/src/main/AndroidManifest.xml`
  - `android:usesCleartextTraffic="false"`여야 한다.

심사 빌드에서는 아래 옵션을 절대 붙이지 않는다.

```powershell
--dart-define=ADS_ENABLED=true
--dart-define=POST_SHARING_ENABLED=true
--dart-define=API_BASE_URL=http://...
```

## 3. BE 코드 및 운영 준비 확인

BE로 이동한다.

```powershell
cd C:\develop\BE\backend
```

컴파일을 확인한다.

```powershell
.\gradlew.bat compileJava
```

정상 결과:

```text
BUILD SUCCESSFUL
```

운영 프로파일에서 확인할 것:

- `SPRING_PROFILES_ACTIVE=prod`
- Swagger/OpenAPI 비활성화
  - `springdoc.api-docs.enabled=false`
  - `springdoc.swagger-ui.enabled=false`
- 운영 로그 레벨 과도하지 않음
- `CORS_ALLOWED_ORIGINS`에 실제 필요한 도메인만 포함
- `WS_ALLOWED_ORIGINS`에 실제 필요한 도메인만 포함
- `DEBUG=false`
- DB/Redis/S3/Firebase/Mail/JWT 환경변수가 모두 운영 값

운영 API가 살아 있어야 한다.

브라우저 또는 정상 HTTPS가 되는 터미널에서 아래 주소를 연다.

```text
https://api.teenple.app/actuator/health
```

기대:

- 응답이 `200`이어야 한다.
- 최소한 `UP` 상태가 확인되어야 한다.

주의:

- 현재 이 Windows 환경의 `curl.exe`는 Schannel 인증서 오류가 발생할 수 있다.
- `curl`이 실패하더라도 브라우저에서 열리면 서버 자체 문제는 아닐 수 있다.
- Play 제출 전에는 브라우저 또는 다른 네트워크 환경에서 반드시 직접 확인한다.

## 4. 공식 웹 페이지 URL 확인

Play Console에 입력할 URL이 모두 실제로 열려야 한다.

브라우저에서 아래 URL을 하나씩 직접 연다.

```text
https://teenple.app/privacy
https://teenple.app/privacy-consent
https://teenple.app/terms
https://teenple.app/support
https://teenple.app/account-deletion
```

각 URL에서 확인할 것:

- 404가 아니어야 한다.
- 빈 페이지가 아니어야 한다.
- TeenPle 서비스명 또는 운영자 정보가 보여야 한다.
- 개인정보처리방침 본문이 보여야 한다.
- 이용약관 본문이 보여야 한다.
- 문의 페이지에 연락 가능한 이메일 또는 안내가 있어야 한다.
- 계정 삭제 페이지에 앱 내 삭제 경로와 웹 요청 방법이 있어야 한다.

정상 확인 후 Play Console에 사용할 URL:

```text
Website URL: https://teenple.app/support
Privacy policy URL: https://teenple.app/privacy
Account deletion URL: https://teenple.app/account-deletion
Support/contact URL: https://teenple.app/support
```

## 5. Android 릴리스 서명 준비

현재 로컬에는 릴리스 서명 파일이 없다. 이 단계가 끝나기 전에는 AAB를 만들 수 없다.

FE로 이동한다.

```powershell
cd C:\develop\FE
```

기존 keystore가 있는지 확인한다.

```powershell
Test-Path android\key.properties
Test-Path android\upload-keystore.jks
```

둘 다 `False`면 새로 만들어야 한다.

업로드 keystore를 생성한다.

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

입력 예시:

```text
Enter keystore password: 강한 비밀번호 입력
Re-enter new password: 같은 비밀번호 입력
What is your first and last name?: TeenPle
What is the name of your organizational unit?: TeenPle
What is the name of your organization?: TeenPle
What is the name of your City or Locality?: Seoul
What is the name of your State or Province?: Seoul
What is the two-letter country code for this unit?: KR
Is CN=TeenPle, OU=TeenPle, O=TeenPle, L=Seoul, ST=Seoul, C=KR correct?: yes
Enter key password for <upload>: 엔터 또는 같은 비밀번호
```

주의:

- keystore 비밀번호를 잃어버리면 이후 업데이트가 매우 번거롭다.
- `android/upload-keystore.jks` 파일과 비밀번호를 안전한 비밀번호 관리자 또는 별도 보관소에 백업한다.
- 이 파일은 절대 GitHub에 올리지 않는다.

`android/key.properties` 파일을 만든다.

기존 예시 파일을 연다.

```powershell
notepad android\key.properties.example
```

새 파일을 만든다.

```powershell
notepad android\key.properties
```

아래 내용을 입력한다.

```properties
storeFile=../upload-keystore.jks
storePassword=위에서 만든 keystore 비밀번호
keyAlias=upload
keyPassword=위에서 만든 key 비밀번호
```

저장 후 확인한다.

```powershell
Test-Path android\key.properties
Test-Path android\upload-keystore.jks
```

정상 결과:

```text
True
True
```

Git에 올라가지 않는지 확인한다.

```powershell
git status --short
```

정상:

- `android/key.properties`가 표시되지 않아야 한다.
- `android/upload-keystore.jks`가 표시되지 않아야 한다.

만약 표시된다면 `.gitignore`를 확인하고 절대 커밋하지 않는다.

## 6. 앱 버전 확인

`pubspec.yaml`을 연다.

```powershell
notepad pubspec.yaml
```

현재 값:

```yaml
version: 1.0.0+1
```

의미:

- `1.0.0`: 사용자에게 보이는 버전명
- `1`: Play Console이 비교하는 versionCode

규칙:

- Play Console에 한 번 업로드한 versionCode는 다시 사용할 수 없다.
- 내부 테스트에 올린 AAB도 같은 versionCode 재업로드가 막힐 수 있다.
- 이미 `+1`을 올린 적이 있으면 반드시 올린다.

예시:

```yaml
version: 1.0.1+2
```

첫 업로드라면 `1.0.0+1`로 진행해도 된다.

## 7. Target API 요구사항 확인

Google Play는 제출 시점의 target API 요구사항을 검사한다.

현재 프로젝트는 `android/app/build.gradle.kts`에서 Flutter 기본값을 사용한다.

```kotlin
compileSdk = flutter.compileSdkVersion
targetSdk = flutter.targetSdkVersion
```

현재 로컬 Flutter SDK 확인 결과:

```text
compileSdk 36
targetSdk 36
```

따라서 현재 Google Play target API 요구사항에는 대응 가능하다.

그래도 Play Console 업로드 후 다음 경고가 뜨면 제출 전에 해결한다.

```text
Your app must target Android ...
```

경고가 뜨면 확인할 파일:

- `android/app/build.gradle.kts`
- `android/settings.gradle.kts`
- Android Gradle Plugin 버전
- Flutter SDK 버전

## 8. AAB 빌드

FE로 이동한다.

```powershell
cd C:\develop\FE
```

깨끗하게 빌드한다.

```powershell
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

정상 결과:

```text
Built build\app\outputs\bundle\release\app-release.aab
```

AAB 위치:

```text
C:\develop\FE\build\app\outputs\bundle\release\app-release.aab
```

만약 아래 오류가 나오면 5단계로 돌아간다.

```text
Missing release signing configuration.
Create android/key.properties with storeFile, storePassword, keyAlias, and keyPassword before building a release.
```

이번 심사 빌드에서 사용하면 안 되는 명령:

```powershell
flutter build appbundle --release --dart-define=ADS_ENABLED=true
flutter build appbundle --release --dart-define=POST_SHARING_ENABLED=true
flutter build appbundle --release --dart-define=API_BASE_URL=http://localhost:8080
```

## 9. 릴리스 APK 실기기 테스트

AAB는 직접 설치가 불편하므로, 같은 release 설정으로 APK도 만들어 실기기에서 확인한다.

```powershell
flutter build apk --release
```

APK 위치:

```text
C:\develop\FE\build\app\outputs\flutter-apk\app-release.apk
```

Android 기기를 USB로 연결한다.

```powershell
adb devices
```

기기가 보이면 설치한다.

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

실기기에서 확인할 것:

- 앱이 정상 실행된다.
- 로그인 화면이 정상 표시된다.
- 심사용 계정으로 로그인된다.
- 학교 인증 완료 계정으로 메인 피드에 진입된다.
- 학교 피드가 `https://api.teenple.app`에서 정상 로드된다.
- 게시글 목록에 광고 빈칸이 없다.
- 게시글 상세에 광고 빈칸이 없다.
- 공유 버튼이 보이지 않는다.
- 게시글 작성이 된다.
- 게시글 상세 진입이 된다.
- 댓글 작성이 된다.
- 게시글 신고가 된다.
- 댓글 신고가 된다.
- 사용자 차단이 된다.
- 채팅 화면 진입이 된다.
- 급식 화면 진입이 된다.
- 시간표 화면 진입이 된다.
- 프로필 화면 진입이 된다.
- 설정 화면 진입이 된다.
- 문의하기 화면 진입이 된다.
- 회원 탈퇴 화면 진입이 된다.
- 이미지 업로드가 된다.
- 푸시 알림 권한 요청 문구가 자연스럽다.
- 네트워크가 잠시 끊겨도 앱이 비정상 종료되지 않는다.

회원 탈퇴 경로:

```text
프로필 또는 설정 -> 회원 탈퇴
```

문의 경로:

```text
프로필 또는 설정 -> 문의하기
```

## 10. 심사용 계정 준비

심사자가 학교 인증 절차에 막히면 반려될 수 있다. 반드시 인증 완료 계정을 준비한다.

심사용 일반 계정 조건:

- 로그인 가능
- 이메일 인증 완료
- 전화번호 인증 완료
- 학교 인증 완료
- 탈퇴 대기 상태 아님
- 정지/제재 상태 아님
- 메인 피드 접근 가능
- 게시글 상세, 댓글, 신고, 차단, 문의, 설정, 회원 탈퇴 화면 접근 가능

권장:

- 심사용 계정 비밀번호는 심사 기간 동안 바꾸지 않는다.
- 심사 중 계정을 삭제하거나 정지하지 않는다.
- 심사용 계정이 속한 학교/게시판에 최소한 테스트 가능한 게시글이 있어야 한다.

Play Console App access에 넣을 문구 예시:

```text
Login is required to use TeenPle.

Reviewer account:
Email: reviewer@example.com
Password: ********

This account is already school-verified.
After login, reviewers can access:
- School feed
- Post list and post detail
- Post and comment creation
- Post and comment reporting
- User blocking
- Chat
- Profile and settings
- In-app inquiry
- Account deletion flow

Official URLs:
Privacy Policy: https://teenple.app/privacy
Terms: https://teenple.app/terms
Support: https://teenple.app/support
Account deletion: https://teenple.app/account-deletion

Contact: teenple.official@gmail.com
```

실제 제출 시 `reviewer@example.com`과 `********`는 실제 계정으로 바꾼다.

## 11. Google Play 개발자 계정 등록

Play Console 계정이 아직 없으면 이 단계를 먼저 한다. 앱 생성은 개발자 계정 등록이 끝난 뒤에 가능하다.

브라우저에서 Google Play Console에 접속한다.

```text
https://play.google.com/console
```

사용할 Google 계정으로 로그인한다.

권장:

- 회사/팀 공식 계정이 있으면 그 계정을 사용한다.
- 개인 Gmail로 등록하면 개발자 계정 유형이 개인 계정이 될 수 있다.
- 개인 계정으로 2023-11-13 이후 새로 등록하면 Production 출시 전에 closed testing 12명/14일 요구사항이 적용될 수 있다.
- 장기 운영할 서비스라면 가능하면 조직 계정 또는 운영용 Google 계정을 사용하는 것이 관리에 유리하다.

처음 접속하면 개발자 계정 등록 화면이 열린다.

계정 유형을 선택한다.

```text
Personal account
Organization account
```

선택 기준:

- 개인 개발자/개인 사업자처럼 개인 명의로 운영하면 `Personal account`
- 법인/단체/회사 명의로 운영하고 D-U-N-S, 조직 정보, 담당자 정보를 제공할 수 있으면 `Organization account`

주의:

- 어떤 유형을 선택할지는 실제 운영 주체와 결제/세금/신원확인 정보 기준으로 정한다.
- 잘못된 유형으로 등록하면 나중에 심사/인증/결제 정보에서 문제가 생길 수 있다.

개발자 이름을 입력한다.

```text
Developer name: TeenPle
```

주의:

- 이 이름은 Play Store에 표시될 수 있다.
- 실제 운영자명, 브랜드명, 회사명과 충돌하지 않게 입력한다.

연락처 정보를 입력한다.

입력 예시:

```text
Contact email: teenple.official@gmail.com
Contact phone number: 실제 연락 가능한 전화번호
Website: https://teenple.app/support
```

주의:

- 심사나 정책 이슈 연락을 받을 수 있는 이메일을 사용한다.
- 연락처 인증이 요구되면 실제 받을 수 있는 번호를 사용한다.

개발자 계정 등록비를 결제한다.

```text
Registration fee: Google Play Console에서 표시되는 일회성 등록비
Payment method: 실제 결제 가능한 카드
```

결제 후 본인 또는 조직 인증을 진행한다.

나올 수 있는 인증:

- 이름/주소 확인
- 전화번호 인증
- 이메일 인증
- 신분증 또는 조직 서류 확인
- 결제 프로필 확인

인증이 끝나면 Play Console 홈으로 진입할 수 있다.

등록 후 반드시 확인할 것:

- Play Console 왼쪽 메뉴 또는 홈이 정상 표시된다.
- `All apps` 또는 앱 목록 화면에 접근할 수 있다.
- 개발자 계정 상태에 미완료 인증 항목이 없는지 확인한다.
- Production 출시 접근 권한에 closed testing 요구사항이 있는지 확인한다.

closed testing 요구사항 확인 경로:

```text
Play Console -> Test and release -> Production
```

또는 Play Console 홈의 안내 카드에서 production access 상태를 확인한다.

요구사항이 표시되면:

- 바로 Production 제출은 불가능하다.
- Internal testing 후 Closed testing을 12명 이상, 14일 이상 진행해야 할 수 있다.
- 자세한 절차는 이 문서의 `Closed testing 요구사항 확인` 단계를 따른다.

## 12. Play Console 앱 생성

브라우저에서 Google Play Console에 접속한다.

```text
https://play.google.com/console
```

왼쪽 또는 상단에서 `All apps`로 이동한다.

`Create app`을 누른다.

입력:

```text
App name: TeenPle
Default language: Korean (South Korea) 또는 Korean
App or game: App
Free or paid: Free
```

체크:

- Developer Program Policies 동의
- US export laws declaration 동의
- Play App Signing 약관 동의

`Create app`을 누른다.

## 13. Store listing 작성

Play Console에서 앱을 선택한다.

왼쪽 메뉴에서 다음 경로로 이동한다.

```text
Grow users -> Store presence -> Main store listing
```

또는 Play Console UI에 따라:

```text
Store presence -> Main store listing
```

입력 항목:

```text
App name: TeenPle
Short description: 학교 인증 기반 10대 커뮤니티
Full description: 실제 서비스 설명을 입력한다. 숨겨진 기능, 아직 출시하지 않은 공유 기능, 광고 기능은 쓰지 않는다.
```

Full description에 포함할 내용:

- 학교 인증 기반 커뮤니티
- 게시글과 댓글
- 채팅
- 급식/시간표 등 학교생활 기능
- 신고/차단 등 안전 기능
- 문의 및 계정 삭제 경로

Full description에 쓰면 안 되는 내용:

- 아직 숨겨둔 공유 기능
- 아직 켜지 않은 광고 기능
- 실제로 심사자가 접근할 수 없는 기능
- 과장된 키워드 반복

그래픽 항목:

- App icon: Play Console 요구 크기 PNG 업로드
- Feature graphic: Play Console 요구 크기 이미지 업로드
- Phone screenshots: 실제 심사 빌드 화면으로 촬영한 이미지 업로드

스크린샷 주의:

- 광고 영역이 보이면 안 된다.
- 공유 버튼이 보이면 안 된다.
- 심사 빌드와 다른 UI를 올리지 않는다.
- 로그인 후 주요 화면을 보여준다.

연락처/URL:

```text
Website: https://teenple.app/support
Email: teenple.official@gmail.com
Phone: 없으면 비워둔다.
Privacy policy: https://teenple.app/privacy
```

저장 버튼:

```text
Save
```

## 14. App content - Privacy Policy

왼쪽 메뉴에서 이동한다.

```text
Policy and programs -> App content
```

`Privacy Policy` 항목을 찾는다.

`Start` 또는 `Manage`를 누른다.

입력:

```text
Privacy policy URL: https://teenple.app/privacy
```

`Save` 또는 `Submit`을 누른다.

## 15. App content - Ads

`App content`에서 `Ads`를 찾는다.

`Start` 또는 `Manage`를 누른다.

질문:

```text
Does your app contain ads?
```

이번 심사 빌드 기준 답변:

```text
No
```

근거:

- 광고 SDK 없음
- AdMob ID 없음
- 광고 지면 비활성
- `ADS_ENABLED=false`

저장한다.

나중에 광고를 켜는 업데이트를 하면 반드시 이 답변을 `Yes`로 바꾸고 Data safety도 다시 확인한다.

## 16. App content - App Access

`App content`에서 `App access`를 찾는다.

`Start` 또는 `Manage`를 누른다.

질문이 나오면 다음처럼 선택한다.

```text
All or some functionality is restricted
```

이유:

- TeenPle은 로그인이 필요하다.
- 학교 인증이 완료된 사용자만 주요 기능에 접근한다.

`Add instructions` 또는 `Add new instructions`를 누른다.

입력:

```text
Name: TeenPle reviewer account
Username / Email: 실제 심사용 이메일
Password: 실제 비밀번호
Other instructions: 아래 문구 붙여넣기
```

Other instructions 예시:

```text
Login is required to use TeenPle.

Use the account below:
Email: 실제 심사용 이메일
Password: 실제 비밀번호

This account is already school-verified.
After login, reviewers can access the school feed, posts, comments, report and block flows, chat, profile, settings, inquiry, and account deletion flow.

Please do not create a new account for review because school verification may require admin approval.

Official URLs:
Privacy Policy: https://teenple.app/privacy
Terms: https://teenple.app/terms
Support: https://teenple.app/support
Account deletion: https://teenple.app/account-deletion
```

저장한다.

## 17. App content - Target audience and content

`App content`에서 `Target audience and content`를 찾는다.

`Start` 또는 `Manage`를 누른다.

입력은 실제 운영 정책에 맞춘다.

TeenPle 기준으로 신중히 확인할 것:

- 서비스가 실제로 대상으로 하는 연령
- 14세 미만 사용자를 대상으로 하지 않는지
- 고등학생/청소년 커뮤니티 성격
- UGC가 존재한다는 점
- 신고/차단/관리자 moderation이 있다는 점

답변 원칙:

- 실제 사용자 대상보다 낮은 연령을 선택하지 않는다.
- 어린이 대상 앱처럼 보이게 선택하지 않는다.
- 개인정보처리방침과 앱 설명이 같은 방향이어야 한다.

저장한다.

## 18. App content - Content Rating

`App content`에서 `Content rating`을 찾는다.

`Start` 또는 `Manage`를 누른다.

설문에서 실제 기능 기준으로 답한다.

TeenPle에 있는 기능:

- 사용자 게시글
- 댓글
- 채팅
- 이미지 업로드
- 신고
- 차단
- 관리자 moderation

답변 원칙:

- 사용자가 만든 콘텐츠가 있으면 UGC 관련 질문에 정확히 답한다.
- 채팅이 있으면 사용자 간 커뮤니케이션 질문에 정확히 답한다.
- 폭력/성적/불법 콘텐츠를 의도적으로 제공하지 않더라도, 사용자가 올릴 수 있는 구조와 moderation 정책을 고려한다.

완료 후 rating 결과를 저장한다.

## 19. App content - Data Safety

`App content`에서 `Data safety`를 찾는다.

`Start` 또는 `Manage`를 누른다.

Data safety는 실제 수집/처리와 개인정보처리방침이 일치해야 한다.

TeenPle에서 수집 또는 처리 가능성이 있는 데이터:

- 이메일
- 전화번호
- 로그인 ID
- 닉네임
- 학교명
- 학년/반/번호
- 학생증 또는 학생 인증 이미지
- 프로필 이미지
- 게시글
- 댓글
- 채팅 메시지
- 업로드 이미지/첨부 파일
- 신고 내용
- 제재/경고 이력
- 문의 내용
- FCM push token
- 기기/OS/app version 정보
- IP 주소
- 로그인/이용 기록

사용 목적:

- 계정 생성 및 로그인
- 학교 인증
- 서비스 제공
- 사용자 간 커뮤니케이션
- 신고 처리 및 moderation
- 부정 이용 방지
- 보안
- 푸시 알림 발송
- 문의 응대
- 계정 복구/탈퇴 처리

답변 시 주의:

- 광고가 꺼진 심사 빌드이므로 광고 목적 데이터 수집으로 표시하지 않는다.
- 실제로 수집하는 데이터는 누락하지 않는다.
- 학생 인증 이미지, 게시글/댓글/채팅/신고/문의는 개인정보처리방침과 일치해야 한다.
- 데이터 삭제 요청 가능 여부는 계정 삭제 페이지와 일치해야 한다.

저장 후 Play Console이 표시하는 미완료 항목이 없는지 확인한다.

## 20. App content - Data Deletion

`App content`에서 `Data deletion`을 찾는다.

`Start` 또는 `Manage`를 누른다.

입력:

```text
Account deletion URL: https://teenple.app/account-deletion
```

질문이 나오면 실제 정책에 맞게 답한다.

TeenPle 기준:

- 앱 내 계정 삭제 경로 있음
- 웹에서 계정 삭제 요청 방법 안내 있음
- 탈퇴 요청 후 7일 유예 기간 있음
- 7일 이내 복구 가능
- 이후 개인정보 삭제 또는 법령/운영정책상 필요한 정보만 보관
- 게시글/댓글은 정책에 따라 삭제 또는 익명 처리될 수 있음

앱 내 삭제 경로 설명:

```text
Profile or Settings -> 회원 탈퇴
```

저장한다.

## 21. App content - Sensitive permissions

Play Console이 민감 권한 선언을 요구하면 실제 용도로 답한다.

현재 Android manifest 권한:

```text
INTERNET
POST_NOTIFICATIONS
READ_MEDIA_IMAGES
READ_EXTERNAL_STORAGE, maxSdkVersion=32
WRITE_EXTERNAL_STORAGE, maxSdkVersion=28
```

설명 예시:

```text
Photo and media access is used only when users upload images for profile, posts, chat, or school verification.
Notification permission is used to send service notifications such as comments, chat messages, verification results, warnings, and inquiry replies.
Internet access is required to communicate with the TeenPle server.
```

주의:

- 사용하지 않는 권한을 추가하지 않는다.
- 백그라운드 위치, SMS, 통화 기록 같은 권한은 현재 없어야 한다.

## 22. UGC 정책 설명 준비

TeenPle은 사용자 생성 콘텐츠가 있으므로 Play 심사 설명에 안전 정책을 적는다.

앱에 있어야 하는 기능:

- 이용약관 동의
- 게시글 신고
- 댓글 신고
- 사용자 차단
- 관리자 신고 관리
- 관리자 제재/경고

Review notes 또는 App access instructions에 넣을 수 있는 문구:

```text
TeenPle is a school-verified community app.
Users can create posts, comments, and chat messages.
Users can report inappropriate posts and comments.
Users can block other users.
Admins can review reports and moderate content and users.
```

## 23. AAB 내부 테스트 업로드

Play Console에서 앱을 선택한다.

왼쪽 메뉴:

```text
Test and release -> Testing -> Internal testing
```

처음이면:

```text
Create track
```

또는:

```text
Create new release
```

App signing 관련 화면이 나오면:

- Google Play App Signing 사용에 동의한다.
- 업로드 키로 서명한 AAB를 올린다.

`App bundles` 영역에서:

```text
Upload
```

아래 파일을 선택한다.

```text
C:\develop\FE\build\app\outputs\bundle\release\app-release.aab
```

Release name:

```text
1.0.0
```

Release notes 예시:

```text
TeenPle initial Android release for review.
```

Korean release notes 예시:

```text
TeenPle 안드로이드 첫 출시 빌드입니다.
```

`Next` 또는 `Review release`를 누른다.

경고가 나오면 읽고 처리한다.

치명 경고 예시:

- target API 부족
- versionCode 중복
- 서명 오류
- 개인정보처리방침 누락
- App content 미완료

문제가 없으면:

```text
Start rollout to Internal testing
```

또는 UI에 따라:

```text
Publish release
```

## 24. 내부 테스트 설치 및 Pre-launch report 확인

Internal testing에 테스터 이메일을 추가한다.

경로:

```text
Test and release -> Testing -> Internal testing -> Testers
```

테스터 목록을 만들고 이메일을 추가한다.

테스터에게 opt-in 링크를 전달한다.

실제 Android 기기에서 Play Store 테스트 링크로 설치한다.

설치 후 다시 확인:

- 앱 실행
- 로그인
- 메인 피드
- 게시글/댓글
- 신고/차단
- 문의
- 회원 탈퇴 화면
- 이미지 업로드
- 푸시 권한

Pre-launch report 확인:

```text
Test and release -> Testing -> Pre-launch report
```

확인할 항목:

- Crashes
- ANRs
- Security warnings
- Privacy warnings
- Accessibility warnings
- Login failure
- Target API warnings
- Permission warnings

치명적인 Crash/ANR/정책 경고가 있으면 Production 제출 전에 수정한다.

## 25. Closed testing 요구사항 확인

Google Play 개발자 계정이 개인 계정이고 2023-11-13 이후 생성됐다면 Production 전에 closed testing 요구사항이 적용될 수 있다.

Play Console에서 확인:

```text
Test and release -> Production
```

또는 Play Console 홈의 안내 카드에서 production access 상태를 확인한다.

요구될 수 있는 내용:

- 12명 이상 테스터
- 14일 이상 closed test 참여
- Production access 신청

요구사항이 뜨면 바로 Production 제출이 아니라 closed testing부터 진행한다.

Production access 신청 때 준비할 답변:

- 테스터를 어떻게 모집했는지
- 테스터가 앱을 어떻게 사용했는지
- 어떤 피드백을 받았는지
- 피드백으로 무엇을 수정했는지
- 왜 production 출시 준비가 되었는지

## 26. Production 제출

Internal testing과 Pre-launch report가 깨끗하고, closed testing 요구사항이 없거나 완료되었을 때 진행한다.

왼쪽 메뉴:

```text
Test and release -> Production
```

`Create new release`를 누른다.

이미 내부 테스트에 올린 AAB를 선택하거나 새 AAB를 업로드한다.

Release name:

```text
1.0.0
```

Release notes:

```text
TeenPle initial Android release.
```

국가/지역을 선택한다.

권장:

- 처음에는 실제 서비스 대상 국가만 선택한다.
- 한국 서비스라면 Korea/South Korea 중심으로 시작한다.

`Review release`를 누른다.

모든 경고를 확인한다.

반드시 완료되어야 하는 항목:

- Store listing complete
- App content complete
- Privacy policy complete
- Data safety complete
- Data deletion complete
- App access complete
- Content rating complete
- Target audience complete
- AAB uploaded
- No critical release warnings

문제가 없으면:

```text
Submit for review
```

가능하면 Managed publishing을 켠다.

경로:

```text
Publishing overview -> Managed publishing
```

권장:

```text
Managed publishing: On
```

이렇게 하면 승인 즉시 자동 출시되지 않고, 승인 후 직접 게시할 수 있다.

## 27. 최종 제출 전 체크리스트

로컬:

- [ ] FE `main` 최신 상태
- [ ] BE 운영 서버 정상
- [ ] FE `flutter analyze` 통과
- [ ] BE `compileJava` 통과
- [ ] `android/key.properties` 존재
- [ ] `android/upload-keystore.jks` 존재
- [ ] keystore/password 별도 백업 완료
- [ ] `versionCode`가 이전 업로드보다 큼
- [ ] `flutter build appbundle --release` 성공
- [ ] `app-release.aab` 생성
- [ ] release APK 실기기 테스트 완료

기능:

- [ ] 로그인 성공
- [ ] 심사용 계정 학교 인증 완료
- [ ] 학교 피드 로드
- [ ] 게시글 목록/상세 로드
- [ ] 게시글 작성/삭제 테스트
- [ ] 댓글 작성/삭제 테스트
- [ ] 게시글 신고 테스트
- [ ] 댓글 신고 테스트
- [ ] 사용자 차단 테스트
- [ ] 문의하기 접근
- [ ] 회원 탈퇴 화면 접근
- [ ] 이미지 업로드 테스트
- [ ] 공유 버튼 숨김
- [ ] 광고 영역 없음

웹/API:

- [ ] `https://teenple.app/privacy` 열림
- [ ] `https://teenple.app/privacy-consent` 열림
- [ ] `https://teenple.app/terms` 열림
- [ ] `https://teenple.app/support` 열림
- [ ] `https://teenple.app/account-deletion` 열림
- [ ] `https://api.teenple.app/actuator/health` 정상

Play Console:

- [ ] App name: TeenPle
- [ ] Default language: Korean
- [ ] App type: App
- [ ] Free
- [ ] Store listing 입력 완료
- [ ] 실제 심사 빌드 스크린샷 업로드
- [ ] Privacy policy URL 입력
- [ ] Ads: No
- [ ] App access 심사용 계정 입력
- [ ] Target audience 입력
- [ ] Content rating 완료
- [ ] Data safety 완료
- [ ] Data deletion URL 입력
- [ ] UGC 신고/차단/moderation 설명 준비
- [ ] Internal testing 업로드 완료
- [ ] Pre-launch report 치명 이슈 없음
- [ ] Closed testing 요구사항 확인
- [ ] Production release 검토 완료
- [ ] Submit for review 완료

## 28. 반려를 피하기 위한 주의사항

아래 상태로 제출하지 않는다.

- 심사용 계정이 로그인되지 않음
- 심사용 계정이 학교 인증 대기 상태
- 심사용 계정이 정지/탈퇴 대기 상태
- 개인정보처리방침 URL 404
- 계정 삭제 URL 404
- 앱 안에는 계정 생성이 있는데 삭제 경로가 없음
- Data safety에서 실제 수집 데이터를 누락
- Ads를 No로 답했는데 광고 SDK/광고 지면이 존재
- 스크린샷에 현재 빌드에 없는 기능이 보임
- 앱 설명에 공유 기능처럼 숨겨둔 기능을 작성
- AAB가 debug signing 또는 서명 누락 상태
- versionCode 중복
- target API 경고 미해결
- API 서버가 심사 기간 중 내려감

## 29. 공식 참고 문서

- Create and set up your app: https://support.google.com/googleplay/android-developer/answer/9859152
- Prepare your app for review: https://support.google.com/googleplay/android-developer/answer/9859455
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- User generated content policy: https://support.google.com/googleplay/android-developer/answer/9876937
- Target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Personal account testing requirements: https://support.google.com/googleplay/android-developer/answer/14151465
