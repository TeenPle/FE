# Google Play 출시 제출 상세 가이드

Last reviewed: 2026-07-02

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
- 코드, Play Console 입력, 개인정보처리방침, 데이터 보안 답변은 서로 일치해야 한다.

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
개인정보처리방침 URL: https://teenple.app/privacy
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

Play Console 앱 액세스에 넣을 문구 예시:

```text
TeenPle 사용에는 로그인이 필요합니다.

Reviewer account:
Email: reviewer@example.com
비밀번호: ********

이 계정은 학교 인증이 완료된 심사용 계정입니다.
로그인 후 심사자는 다음 기능에 접근할 수 있습니다.
- 학교 피드
- 게시글 목록 및 게시글 상세
- 게시글/댓글 작성
- 게시글/댓글 신고
- 사용자 차단
- 채팅
- 프로필 및 설정
- 문의 경로
- 계정 삭제 흐름

공식 URL:
개인정보처리방침: https://teenple.app/privacy
이용약관: https://teenple.app/terms
지원/문의: https://teenple.app/support
계정 삭제: https://teenple.app/account-deletion

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
- 개인 계정으로 2023-11-13 이후 새로 등록하면 프로덕션 출시 전에 비공개 테스트 12명/14일 요구사항이 적용될 수 있다.
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
- `모든 앱` 또는 앱 목록 화면에 접근할 수 있다.
- 개발자 계정 상태에 미완료 인증 항목이 없는지 확인한다.
- 프로덕션 출시 접근 권한에 비공개 테스트 요구사항이 있는지 확인한다.

closed testing 요구사항 확인 경로:

```text
Play Console -> 테스트 및 출시 -> 프로덕션
```

또는 Play Console 홈의 안내 카드에서 production access 상태를 확인한다.

요구사항이 표시되면:

- 바로 프로덕션 제출은 불가능하다.
- 내부 테스트 후 비공개 테스트를 12명 이상, 14일 이상 진행해야 할 수 있다.
- 자세한 절차는 이 문서의 `비공개 테스트 요구사항 확인` 단계를 따른다.

## 12. Play Console 앱 생성

브라우저에서 Google Play Console에 접속한다.

```text
https://play.google.com/console
```

왼쪽 또는 상단에서 `모든 앱`으로 이동한다.

`앱 만들기`를 누른다.

입력:

```text
앱 이름: TeenPle
기본 언어: 한국어(대한민국) 또는 한국어
앱 또는 게임: 앱
무료 또는 유료: 무료
```

체크:

- 개발자 프로그램 정책 동의
- 미국 수출 법규 선언 동의
- Play 앱 서명 약관 동의

`앱 만들기`를 누른다.

## 13. 스토어 등록정보 작성

Play Console에서 앱을 선택한다.

왼쪽 메뉴에서 다음 경로로 이동한다.

```text
사용자 늘리기 -> 스토어 등록정보 -> 기본 스토어 등록정보
```

또는 Play Console UI에 따라 왼쪽 메뉴에서 `스토어 등록정보` 또는 `기본 스토어 등록정보`를 찾는다.

스토어 등록정보는 Google Play 스토어에서 사용자가 보는 앱 소개 페이지다.  
앱 이름, 짧은 설명, 긴 설명, 아이콘, 대표 이미지, 스크린샷, 문의 이메일, 개인정보처리방침 URL을 넣는 곳이다.

이번 출시에서는 Play Store에 보이는 내용과 실제 심사 빌드가 반드시 일치해야 한다.

작성 원칙:

- 아직 숨겨둔 공유 기능은 쓰지 않는다.
- 광고 기능은 이번 빌드에서 꺼져 있으므로 쓰지 않는다.
- “전국 1위”, “완전 안전”처럼 증명하기 어려운 표현은 쓰지 않는다.
- 채팅, 게시글, 댓글처럼 UGC가 있는 기능은 숨기지 않는다.
- 신고/차단/운영자 검토 기능을 설명에 포함한다.

### 13-1. 앱 세부정보 입력

입력값:

```text
앱 이름: TeenPle
```

앱 이름은 스토어에 그대로 표시된다.  
Play Console 앱 생성 단계에서 이미 입력했더라도 기본 스토어 등록정보에서 다시 확인한다.

### 13-2. 간단한 설명 입력

짧은 설명은 Play Store에서 앱 이름 아래에 보이는 한 줄 소개다. 아래 문구를 그대로 사용한다.

```text
학교 인증 기반 청소년 커뮤니티
```

만약 글자 수 제한이나 표현 검토가 필요하면 아래 대체 문구를 사용한다.

```text
학교 인증으로 만나는 청소년 커뮤니티
```

### 13-3. 자세한 설명 입력

긴 설명은 사용자가 앱 상세 페이지에서 읽는 본문이다. 최대 4000자까지 입력할 수 있고, 반드시 4000자에 가깝게 채울 필요는 없다. 다만 너무 짧으면 앱의 목적과 기능이 충분히 전달되지 않으므로 아래 문구를 그대로 붙여넣는다.

```text
TeenPle은 학교 인증을 기반으로 같은 학교 학생들이 소통할 수 있는 청소년 커뮤니티 앱입니다.

같은 학교 학생들과 학교생활 이야기를 나누고, 게시글과 댓글로 필요한 정보를 공유할 수 있습니다. 학교 인증을 완료한 사용자는 학교별 게시판을 이용할 수 있으며, 급식과 시간표처럼 일상적으로 확인하는 학교생활 정보도 앱 안에서 빠르게 볼 수 있습니다.

TeenPle에서 할 수 있는 것
- 학교 인증 후 학교별 커뮤니티 이용
- 게시글과 댓글 작성
- 학교생활 정보 확인
- 급식과 시간표 확인
- 사용자 간 채팅
- 프로필과 내 활동 관리
- 부적절한 게시글과 댓글 신고
- 사용자 차단
- 문의 및 계정 삭제 경로 이용

학교 인증 기반 커뮤니티
TeenPle은 학교 인증을 바탕으로 커뮤니티를 제공합니다. 사용자는 가입 과정에서 학교 정보를 입력하고 인증 절차를 거친 뒤 주요 기능을 이용할 수 있습니다. 이를 통해 같은 학교 구성원을 중심으로 더 관련성 높은 이야기를 나눌 수 있습니다.

게시글과 댓글
학교 게시판에서 일상 이야기, 학교생활 정보, 궁금한 점을 글과 댓글로 나눌 수 있습니다. 사용자는 게시글 상세 화면에서 댓글을 확인하고 참여할 수 있습니다.

채팅
앱 안에서 다른 사용자와 채팅할 수 있습니다. 채팅 기능은 학교 커뮤니티 안에서 필요한 대화를 나누기 위한 기능입니다.

급식과 시간표
학교생활에서 자주 확인하는 급식과 시간표 정보를 앱에서 확인할 수 있습니다. 게시판뿐 아니라 학교생활에 필요한 기본 정보까지 한 곳에서 볼 수 있도록 구성했습니다.

안전 기능
TeenPle은 안전한 커뮤니티 운영을 위해 신고와 차단 기능을 제공합니다. 사용자는 부적절한 게시글과 댓글을 신고할 수 있고, 원하지 않는 사용자를 차단할 수 있습니다. 접수된 신고는 운영자가 검토하며, 필요한 경우 콘텐츠 숨김, 경고, 이용 제한 등 운영 정책에 따른 조치를 적용할 수 있습니다.

계정과 개인정보
사용자는 프로필과 설정 화면에서 내 정보를 관리할 수 있으며, 문의와 계정 삭제 경로를 확인할 수 있습니다. 개인정보처리방침과 이용약관은 공식 웹 페이지에서 확인할 수 있습니다.

서비스 문의: teenple.official@gmail.com
개인정보처리방침: https://teenple.app/privacy
이용약관: https://teenple.app/terms
계정 삭제 안내: https://teenple.app/account-deletion
```

주의:

- 자세한 설명은 4000자를 모두 채울 필요는 없다. 위 문구는 약 1300자 수준이라 충분히 사용할 수 있다.
- “앱의 자세한 설명을 추가하세요.”가 계속 뜨면 현재 언어의 `자세한 설명` 입력칸에 붙여넣었는지 확인한다. `간단한 설명` 칸에만 입력하면 이 오류가 계속 뜬다.
- Play Console에서 여러 언어 등록정보를 만든 경우, 현재 편집 중인 언어의 `자세한 설명`이 비어 있으면 오류가 날 수 있다. 기본 언어가 한국어인지 확인한다.
- 붙여넣기 후 반드시 `저장`을 누른다.
- 채팅 기능을 숨기면 심사 중 “실제 기능과 설명 불일치”로 문제가 될 수 있으므로 설명에 포함한다.
- “10대 전용”이라고 강하게 쓰면 연령 정책 검토가 더 민감해질 수 있다. 그래서 스토어 문구는 `청소년 커뮤니티` 정도로 둔다.

### 13-4. 그래픽 업로드

Play Console에서 요구하는 이미지 항목을 업로드한다.

```text
앱 아이콘: 앱 아이콘 PNG
그래픽 이미지: 스토어 상단 대표 이미지
휴대전화 스크린샷: 휴대폰 스크린샷
```

필수 여부:

- 앱 아이콘: 필수
- 그래픽 이미지: 필수
- 스크린샷: 전체 기기 유형을 통틀어 최소 2장 필수
- 휴대전화 스크린샷: 일반 Android 앱 첫 제출에서는 사실상 필수로 준비한다.
- 7인치 태블릿 / 10인치 태블릿 / Chromebook: Play Console에 항목이 보여도 보통 권장 또는 대형 화면 노출 최적화용이다. 빨간 필수 표시가 없으면 첫 제출에서는 비워도 된다.
- Android XR: Android XR용 앱으로 배포하거나 XR 등록정보를 구성하는 경우에 준비한다. 일반 휴대폰 앱이면 비워도 된다.

TeenPle 첫 제출 기준 권장:

```text
휴대전화 스크린샷: 4~8장 업로드
7인치 태블릿 스크린샷: 선택
10인치 태블릿 스크린샷: 선택
Chromebook 스크린샷: 선택
Android XR 스크린샷: 선택
```

태블릿 기기가 없으면 Android Studio 에뮬레이터로 촬영해도 된다. 단, 실제 앱 화면이어야 하고, 화면이 늘어나거나 깨지거나 겹치면 태블릿 스크린샷은 첫 제출에서 넣지 않는 편이 낫다. 선택 항목에 품질 낮은 이미지를 넣는 것보다 휴대전화 스크린샷만 정확하게 올리는 것이 안전하다.

스크린샷은 반드시 이번 release 빌드 또는 Play 내부 테스트 빌드에서 촬영한다.

권장 스크린샷 구성:

```text
1. 로그인 또는 시작 화면
2. 학교 피드/게시판 목록
3. 게시글 상세와 댓글
4. 글쓰기 화면
5. 채팅 목록 또는 채팅방
6. 급식 화면
7. 시간표 화면
8. 프로필 또는 설정 화면
```

스크린샷에서 피해야 할 것:

- 실제 학생 개인정보 노출
- 전화번호, 이메일, 학생증 이미지 노출
- 테스트용 욕설/성적 표현/신고 대상 문구 노출
- 광고 영역 노출
- 공유 버튼 노출
- 아직 출시하지 않은 기능 노출
- 관리자 화면 노출

에뮬레이터로 촬영할 때:

- Android Studio Device Manager에서 Pixel 계열 휴대전화 에뮬레이터를 만든다.
- 태블릿 스크린샷이 필요하면 Pixel Tablet 또는 7~10인치 태블릿 프로필을 만든다.
- release APK 또는 Play 내부 테스트 빌드를 설치해서 촬영한다.
- 상태바 알림, 실제 계정 정보, 학생 개인정보가 보이지 않게 한다.
- 태블릿 화면에서 레이아웃이 어색하면 태블릿 섹션에는 올리지 않는다.

테스트 데이터가 보이면 닉네임과 게시글 내용을 자연스러운 예시로 준비한다.

예시:

```text
닉네임: 틴플러
게시글 제목: 오늘 급식 어땠어?
게시글 내용: 점심 메뉴 맛있었는지 궁금해요.
댓글: 저는 괜찮았어요!
```

### 13-5. 연락처 세부정보 입력

연락처/URL:

```text
웹사이트: https://teenple.app/support
이메일: teenple.official@gmail.com
전화번호: 없으면 비워둔다.
개인정보처리방침: https://teenple.app/privacy
```

주의:

- 이메일은 실제로 받을 수 있어야 한다.
- 지원 URL은 `https://teenple.app/support`를 사용한다.
- 개인정보처리방침 URL은 `https://teenple.app/privacy`를 사용한다.
- Play Console이 전화번호를 필수로 요구하지 않으면 비워둔다. 필수로 요구하면 실제 연락 가능한 번호를 입력한다.

저장 버튼:

```text
저장
```

## 14. 앱 콘텐츠 - 개인정보처리방침

왼쪽 메뉴에서 이동한다.

```text
정책 및 프로그램 -> 앱 콘텐츠
```

`개인정보처리방침` 항목을 찾는다.

`시작` 또는 `관리`를 누른다.

입력:

```text
개인정보처리방침 URL: https://teenple.app/privacy
```

`저장` 또는 `제출`을 누른다.

## 15. 앱 콘텐츠 - 광고

`앱 콘텐츠`에서 `광고`를 찾는다.

`시작` 또는 `관리`를 누른다.

질문:

```text
앱에 광고가 포함되어 있나요?
```

이번 심사 빌드 기준 답변:

```text
아니요
```

근거:

- 광고 SDK 없음
- AdMob ID 없음
- 광고 지면 비활성
- `ADS_ENABLED=false`

저장한다.

나중에 광고를 켜는 업데이트를 하면 반드시 이 답변을 `예`로 바꾸고 데이터 보안도 다시 확인한다.

## 16. 앱 콘텐츠 - 앱 액세스

`앱 콘텐츠`에서 `앱 액세스`를 찾는다.

`시작` 또는 `관리`를 누른다.

질문이 나오면 다음처럼 선택한다.

```text
일부 또는 모든 기능이 제한됨
```

이유:

- TeenPle은 로그인이 필요하다.
- 학교 인증이 완료된 사용자만 주요 기능에 접근한다.

`안내 추가` 또는 `새 안내 추가`를 누른다.

입력:

```text
이름: TeenPle 심사용 계정
사용자 이름 / 이메일: 실제 심사용 이메일
비밀번호: 실제 비밀번호
기타 안내: 아래 문구 붙여넣기
```

기타 안내 예시:

```text
TeenPle 사용에는 로그인이 필요합니다.

아래 계정을 사용해주세요.
Email: 실제 심사용 이메일
비밀번호: 실제 비밀번호

이 계정은 학교 인증이 완료된 심사용 계정입니다.
로그인 후 학교 피드, 게시글, 댓글, 신고 및 차단 흐름, 채팅, 프로필, 설정, 문의, 계정 삭제 흐름에 접근할 수 있습니다.

학교 인증은 관리자 승인이 필요할 수 있으므로 심사 중에는 새 계정을 만들지 말고 위 심사용 계정을 사용해주세요.

공식 URL:
개인정보처리방침: https://teenple.app/privacy
이용약관: https://teenple.app/terms
지원/문의: https://teenple.app/support
계정 삭제: https://teenple.app/account-deletion
```

저장한다.

## 17. 앱 콘텐츠 - 타겟층 및 콘텐츠

`앱 콘텐츠`에서 `타겟층 및 콘텐츠`를 찾는다.

`시작` 또는 `관리`를 누른다.

이 항목은 “이 앱을 누구에게 제공할 것인지”를 Google Play에 선언하는 곳이다.  
TeenPle은 학교 인증 기반 청소년 커뮤니티이므로 어린이 대상 앱처럼 답하면 안 된다.

TeenPle 기준으로 신중히 확인할 것:

- 서비스가 실제로 대상으로 하는 연령
- 14세 미만 사용자를 대상으로 하지 않는지
- 고등학생/청소년 커뮤니티 성격
- UGC가 존재한다는 점
- 신고/차단/관리자 moderation이 있다는 점

현재 TeenPle 기준 추천:

```text
대상 연령 그룹:
- 13-15
- 16-17
- 만 18세 이상
```

만약 실제 운영 정책상 고등학생 이상만 받는다면 다음처럼 더 좁게 선택한다.

```text
대상 연령 그룹:
- 16-17
- 만 18세 이상
```

선택하지 않는 것을 권장:

```text
만 13세 미만
```

이유:

- 앱은 학교 인증, 게시글, 댓글, 채팅, 이미지 업로드가 있는 커뮤니티 앱이다.
- 13세 미만 어린이를 대상으로 설계된 앱이 아니다.
- 13세 미만을 선택하면 Google Play Families 정책, 광고 SDK 제한, 아동 개인정보 처리 요구가 훨씬 강해진다.

질문이 나오면 다음 기준으로 답한다.

```text
앱이 어린이의 관심을 끌도록 설계되었나요?
아니요
```

```text
스토어 등록정보가 의도치 않게 어린이의 관심을 끌 수 있나요?
아니요
```

근거:

- 스토어 설명은 `청소년 커뮤니티`, `학교 인증`, `게시글`, `채팅` 중심이다.
- 어린이용 캐릭터, 아동 대상 학습/놀이 표현을 사용하지 않는다.

답변 원칙:

- 실제 사용자 대상보다 낮은 연령을 선택하지 않는다.
- 어린이 대상 앱처럼 보이게 선택하지 않는다.
- 개인정보처리방침과 앱 설명이 같은 방향이어야 한다.
- 앱 설명, 스크린샷, 아이콘이 어린이 앱처럼 보이지 않게 유지한다.

저장한다.

## 18. 앱 콘텐츠 - 콘텐츠 등급

`앱 콘텐츠`에서 `콘텐츠 등급`을 찾는다.

`시작` 또는 `관리`를 누른다.

이 항목은 앱의 콘텐츠 등급을 산정하는 설문이다.  
TeenPle은 게임이 아니라 커뮤니티/소셜 앱에 가깝다.

카테고리 선택이 나오면 현재 앱 기준으로 아래를 선택한다.

```text
카테고리: 소셜 네트워킹 또는 소셜
```

정확한 명칭은 Play Console UI에 따라 다를 수 있다. `소셜`, `커뮤니케이션`, `라이프스타일` 중 고르게 나오면 `소셜` 또는 `소셜 네트워킹`이 가장 가깝다.

TeenPle에 있는 기능:

- 사용자 게시글
- 댓글
- 채팅
- 이미지 업로드
- 신고
- 차단
- 관리자 moderation

설문 추천 답변 기준:

```text
사용자 제작 콘텐츠: 예
사용자가 콘텐츠를 공유하거나 교환할 수 있음: 예
사용자끼리 커뮤니케이션할 수 있음: 예
메시지 또는 채팅: 예
사용자가 이미지를 업로드할 수 있음: 예
검토/신고/차단 기능: 예
```

다음 항목은 현재 코드와 운영 기준상 `No`로 답한다.

```text
실제 현금 도박: 아니요
모의 도박: 아니요
인앱 구매 또는 유료 디지털 상품: 아니요
앱에서 제공하는 성적 콘텐츠: 아니요
앱에서 제공하는 노골적인 폭력 콘텐츠: 아니요
마약, 주류, 담배 홍보: 아니요
제한 없는 웹브라우저 또는 제한 없는 웹 액세스: 아니요
```

주의:

- 외부 링크를 눌렀을 때 브라우저가 열릴 수는 있지만, 앱이 “무제한 웹 브라우저” 기능을 제공하는 것은 아니다.
- 사용자가 부적절한 글을 올릴 가능성은 UGC/moderation 항목에서 다룬다.
- 채팅이 있으므로 사용자 간 커뮤니케이션 항목을 숨기지 않는다.

답변 원칙:

- 사용자가 만든 콘텐츠가 있으면 UGC 관련 질문에 정확히 답한다.
- 채팅이 있으면 사용자 간 커뮤니케이션 질문에 정확히 답한다.
- 폭력/성적/불법 콘텐츠를 의도적으로 제공하지 않더라도, 사용자가 올릴 수 있는 구조와 moderation 정책을 고려한다.

완료 후 rating 결과를 저장한다.

## 19. 앱 콘텐츠 - 데이터 보안

`앱 콘텐츠`에서 `데이터 보안`을 찾는다.

`시작` 또는 `관리`를 누른다.

데이터 보안은 실제 수집/처리와 개인정보처리방침이 일치해야 한다.

이 설문은 “앱이 어떤 데이터를 수집하고, 어떤 목적으로 쓰며, 사용자에게 연결되는지”를 묻는다.  
TeenPle은 로그인/학교 인증/커뮤니티/채팅/신고 기능이 있으므로 `수집하지 않음`으로 답하면 안 된다.

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

### 19-1. 데이터 유형 추천 입력

Play Console UI 명칭은 조금씩 바뀔 수 있으나, 아래 범주를 기준으로 체크한다.

```text
개인 정보
- 이메일 주소
- 전화번호
- 이름 또는 닉네임에 해당하는 사용자 식별 정보
- 사용자 ID
```

```text
사진 및 동영상
- 사진
```

사용 예:

- 프로필 이미지
- 게시글/채팅 이미지
- 학생 인증 이미지

```text
메시지
- 이메일 또는 기타 인앱 메시지
```

사용 예:

- 채팅 메시지
- 문의 내용

```text
앱 활동
- 앱 상호작용
- 기타 사용자 제작 콘텐츠
```

사용 예:

- 게시글
- 댓글
- 신고 내용
- 차단/제재 관련 처리

```text
앱 정보 및 성능
- 비정상 종료 로그
- 진단
```

실제 crash reporting SDK를 쓰지 않더라도 서버 로그나 앱 버전/기기 상태를 장애 대응에 사용한다면 보수적으로 확인한다. 현재 코드에 별도 crash analytics SDK는 보이지 않는다.

```text
기기 또는 기타 ID
- 기기 또는 기타 ID
```

사용 예:

- FCM push token
- 기기/앱 버전 기반 알림 및 보안 처리

### 19-2. 각 데이터의 사용 목적

대부분의 TeenPle 데이터는 아래 목적에 해당한다.

```text
앱 기능
계정 관리
보안, 사기 방지, 규정 준수
개발자 커뮤니케이션
```

광고 관련 목적은 이번 심사 빌드에서 선택하지 않는다.

```text
광고 또는 마케팅: 아니요
```

분석 목적은 실제 analytics SDK를 넣지 않았으므로 기본적으로 선택하지 않는다.  
나중에 Firebase Analytics, Google Analytics, Amplitude 같은 분석 SDK를 넣으면 다시 수정한다.

```text
분석: 아니요
```

### 19-3. 데이터 공유 여부

일반적으로 Google Play 데이터 보안의 “공유됨”은 개발자 외 제3자에게 데이터를 전송하는지를 묻는다.

현재 앱 기준으로 주의할 외부 처리:

- Firebase Cloud Messaging: 푸시 알림 발송
- 운영 서버/API: TeenPle 서비스 제공
- 정적 웹 페이지: 약관/개인정보/문의 안내

Firebase Messaging을 사용하므로 Google/Firebase로 푸시 토큰 등 일부 데이터가 처리될 수 있다. Play Console 질문이 “제3자와 공유”를 넓게 묻는 형태라면 Firebase 문서와 현재 개인정보처리방침을 기준으로 보수적으로 답한다.

확실하지 않으면 `기기 또는 기타 ID` 및 푸시 관련 처리는 숨기지 않는다.

### 19-4. 삭제 가능 여부

계정 삭제 URL과 앱 내 탈퇴 경로가 있으므로 삭제 요청 가능으로 답한다.

```text
사용자가 데이터 삭제를 요청할 수 있음: 예
계정 삭제 URL: https://teenple.app/account-deletion
```

답변 시 주의:

- 광고가 꺼진 심사 빌드이므로 광고 목적 데이터 수집으로 표시하지 않는다.
- 실제로 수집하는 데이터는 누락하지 않는다.
- 학생 인증 이미지, 게시글/댓글/채팅/신고/문의는 개인정보처리방침과 일치해야 한다.
- 데이터 삭제 요청 가능 여부는 계정 삭제 페이지와 일치해야 한다.

저장 후 Play Console이 표시하는 미완료 항목이 없는지 확인한다.

## 20. 앱 콘텐츠 - 데이터 삭제

`앱 콘텐츠`에서 `데이터 삭제`를 찾는다.

`시작` 또는 `관리`를 누른다.

입력:

```text
계정 삭제 URL: https://teenple.app/account-deletion
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
프로필 또는 설정 -> 회원 탈퇴
```

저장한다.

## 21. 앱 콘텐츠 - 민감한 권한

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

검토 메모 또는 앱 액세스 안내에 넣을 문구:

```text
TeenPle은 학교 인증 기반 커뮤니티 앱입니다.
사용자는 로그인과 학교 인증을 완료한 뒤 게시글, 댓글, 채팅 메시지를 작성할 수 있습니다.
사용자는 회원가입 중 이용약관과 개인정보처리방침에 동의해야 합니다.
사용자는 앱 안에서 부적절한 게시글과 댓글을 신고할 수 있습니다.
사용자는 사용자/게시글/댓글 메뉴에서 다른 사용자를 차단할 수 있습니다.
관리자는 신고를 검토하고, 부적절한 콘텐츠를 숨김 처리하며, 악성 사용자에게 경고 또는 이용 제한을 적용할 수 있습니다.
TeenPle은 성인 콘텐츠, 도박, 랜덤 익명 매칭을 주목적으로 제공하지 않습니다.
```

한국어 의미:

- TeenPle은 학교 인증 기반 커뮤니티다.
- 로그인과 학교 인증 후 게시글, 댓글, 채팅을 사용할 수 있다.
- 가입 중 약관과 개인정보처리방침에 동의한다.
- 사용자는 부적절한 게시글/댓글을 신고할 수 있다.
- 사용자는 다른 사용자를 차단할 수 있다.
- 관리자는 신고를 검토하고 콘텐츠 숨김, 경고, 제한 조치를 할 수 있다.
- 성인 콘텐츠, 도박, 랜덤 익명 매칭을 주목적으로 제공하지 않는다.

이 문구는 채팅 기능 때문에 정책 검토가 들어와도 “랜덤 익명 채팅 앱”이 아니라 “학교 인증 커뮤니티 + 안전장치 있음”을 설명하는 역할을 한다.

## 23. AAB 내부 테스트 업로드

Play Console에서 앱을 선택한다.

왼쪽 메뉴:

```text
테스트 및 출시 -> 테스트 -> 내부 테스트
```

처음이면:

```text
트랙 만들기
```

또는:

```text
새 버전 만들기
```

앱 서명 관련 화면이 나오면:

- Google Play App Signing 사용에 동의한다.
- 업로드 키로 서명한 AAB를 올린다.

`App Bundle` 또는 `앱 번들` 영역에서:

```text
업로드
```

아래 파일을 선택한다.

```text
C:\develop\FE\build\app\outputs\bundle\release\app-release.aab
```

버전 이름:

```text
1.0.0
```

출시 노트 예시:

```text
TeenPle initial Android release for review.
```

한국어 출시 노트 예시:

```text
TeenPle 안드로이드 첫 출시 빌드입니다.
```

`다음` 또는 `버전 검토`를 누른다.

경고가 나오면 읽고 처리한다.

치명 경고 예시:

- target API 부족
- versionCode 중복
- 서명 오류
- 개인정보처리방침 누락
- 앱 콘텐츠 미완료

문제가 없으면:

```text
내부 테스트로 출시 시작
```

또는 UI에 따라:

```text
버전 게시
```

## 24. 내부 테스트 설치 및 출시 전 보고서 확인

내부 테스트에 테스터 이메일을 추가한다.

경로:

```text
테스트 및 출시 -> 테스트 -> 내부 테스트 -> 테스터
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

출시 전 보고서 확인:

```text
테스트 및 출시 -> 테스트 -> 출시 전 보고서
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

치명적인 비정상 종료/ANR/정책 경고가 있으면 프로덕션 제출 전에 수정한다.

## 25. 비공개 테스트 요구사항 확인

Google Play 개발자 계정이 개인 계정이고 2023-11-13 이후 생성됐다면 프로덕션 전에 비공개 테스트 요구사항이 적용될 수 있다.

현재 사용자의 계정이 개인 개발자 계정이라면 이 단계는 건너뛰지 않는다.

Play Console에서 확인:

```text
테스트 및 출시 -> 프로덕션
```

또는 Play Console 홈의 안내 카드에서 production access 상태를 확인한다.

요구될 수 있는 내용:

- 12명 이상 테스터
- 14일 이상 closed test 참여
- 프로덕션 액세스 신청

Google 공식 기준:

- 개인 개발자 계정이 2023-11-13 이후 생성된 경우 적용될 수 있다.
- closed test에 최소 12명의 테스터가 opt-in 되어 있어야 한다.
- 프로덕션 액세스 신청 시점에 이 12명이 최근 14일 동안 연속으로 opt-in 상태여야 한다.
- 중간에 opt-out한 테스터는 14일 연속 조건이 다시 시작될 수 있다.
- 조건을 만족한 뒤 Play Console 대시보드에서 `프로덕션 신청` 또는 `프로덕션 액세스 신청`을 누른다.

요구사항이 뜨면 바로 프로덕션 제출이 아니라 비공개 테스트부터 진행한다.

### 25-1. 비공개 테스트 트랙 만들기

왼쪽 메뉴에서 이동한다.

```text
테스트 및 출시 -> 테스트 -> 비공개 테스트
```

처음이면 `트랙 만들기` 또는 `새 트랙 만들기`를 누른다.

트랙 이름:

```text
TeenPle closed test
```

테스터 방식은 이메일 목록을 권장한다.

```text
테스터 -> 이메일 목록 만들기
```

목록 이름:

```text
TeenPle testers
```

테스터 이메일:

```text
최소 12명 이상
권장 15명 이상
```

12명 딱 맞춰 모으면 한 명이 opt-in을 안 하거나 중간에 빠졌을 때 14일 조건을 다시 맞춰야 할 수 있다. 가능하면 15명 이상을 모은다.

테스터에게 전달할 안내 문구:

```text
TeenPle Android 비공개 테스트 참여 안내입니다.

1. 아래 opt-in 링크를 열어 테스트 참여를 눌러주세요.
2. Play Store에서 TeenPle 테스트 버전을 설치해주세요.
3. 14일 동안 테스트에서 나가지 말아주세요. 중간에 나가면 프로덕션 신청 조건에서 제외될 수 있습니다.
4. 앱에서 로그인, 게시글 보기, 댓글, 채팅, 급식, 시간표, 프로필/설정 화면을 한 번씩 확인해주세요.
5. 오류나 불편한 점은 teenple.official@gmail.com 으로 보내주세요.
```

### 25-2. 비공개 테스트 버전 올리기

비공개 테스트 트랙에서 `새 버전 만들기`를 누른다.

앱 번들:

```text
C:\develop\FE\build\app\outputs\bundle\release\app-release.aab
```

버전 이름:

```text
1.0.0
```

출시 노트:

```text
TeenPle Android closed testing release.
```

한국어 릴리스 노트:

```text
TeenPle 안드로이드 비공개 테스트 빌드입니다.
```

검토 후 문제가 없으면 비공개 테스트로 배포한다.

### 25-3. 14일 동안 관리할 것

테스터 상태를 주기적으로 확인한다.

```text
테스트 및 출시 -> 테스트 -> 비공개 테스트 -> 테스터
```

확인할 것:

- 12명 이상이 opt-in 상태인지
- 테스터가 앱을 실제로 설치할 수 있는지
- 로그인/학교 인증 완료 계정으로 테스트 가능한지
- Crash/ANR이 발생하지 않는지
- 신고/차단/계정 삭제 경로가 정상인지

테스터 피드백 기록 양식:

```text
테스트 기간: YYYY-MM-DD ~ YYYY-MM-DD
테스터 수: 00명
테스트 기기: Galaxy S 시리즈, Galaxy A 시리즈 등
테스트한 기능:
- 로그인
- 학교 피드
- 게시글/댓글
- 채팅
- 급식
- 시간표
- 프로필/설정
- 신고/차단
- 계정 삭제 화면

받은 피드백:
- 예: 로그인 후 첫 로딩이 조금 느림
- 예: 시간표 화면에서 빈 데이터 안내가 필요함

반영한 내용:
- 예: 네트워크 오류 문구 확인
- 예: 심사 빌드에서 광고/공유 기능 비활성 상태 확인
```

### 25-4. 프로덕션 액세스 신청

프로덕션 액세스 신청 때 준비할 답변:

- 테스터를 어떻게 모집했는지
- 테스터가 앱을 어떻게 사용했는지
- 어떤 피드백을 받았는지
- 피드백으로 무엇을 수정했는지
- 왜 프로덕션 출시 준비가 되었는지

Play Console에서 조건이 충족되면 대시보드 또는 프로덕션 화면에 `프로덕션 신청` 또는 `프로덕션 액세스 신청` 버튼이 보인다.

답변 예시:

```text
TeenPle의 실제 대상 사용자와 가까운 개인 네트워크 및 학교 관련 네트워크를 통해 테스터를 모집했습니다. 테스터는 Google Play opt-in 링크를 통해 비공개 테스트에 참여했고, 요구되는 테스트 기간 동안 opt-in 상태를 유지했습니다.

테스터는 로그인, 학교 피드, 게시글, 댓글, 채팅, 급식, 시간표, 프로필/설정, 신고, 차단, 계정 삭제 접근 등 주요 사용자 흐름을 테스트했습니다. 또한 심사용 계정이 학교 인증 단계에 막히지 않고 앱 주요 기능에 접근할 수 있는지도 확인했습니다.

피드백은 직접 메시지와 이메일로 수집했습니다. 주요 피드백은 로그인 흐름의 명확성, 로딩 상태, 실제 Android 기기에서 학교 커뮤니티 기능이 정상 작동하는지에 관한 내용이었습니다.

테스트 결과, 릴리스 빌드에서 치명적인 비정상 종료가 없고, 운영 API가 HTTPS로 연결되며, 이번 릴리스에서 광고와 공유 기능이 비활성화되어 있고, 신고/차단/관리자 검토 같은 사용자 제작 콘텐츠 안전 기능을 사용할 수 있음을 확인했습니다.

TeenPle은 핵심 흐름을 실제 기기에서 테스트했고, 정책상 필요한 웹 페이지가 준비되어 있으며, 데이터 보안과 앱 액세스 정보가 완료되어 있고, 사용자 제작 콘텐츠에 대한 명확한 신고/차단 경로를 제공하므로 프로덕션 출시 준비가 되었습니다.
```

프로덕션 액세스 승인에는 보통 며칠이 걸릴 수 있다. 승인 전까지 프로덕션 제출 버튼이 비활성화될 수 있다.

## 26. 프로덕션 제출

내부 테스트와 출시 전 보고서가 깨끗하고, 비공개 테스트 요구사항이 없거나 완료되었을 때 진행한다.

왼쪽 메뉴:

```text
테스트 및 출시 -> 프로덕션
```

`새 버전 만들기`를 누른다.

이미 내부 테스트에 올린 AAB를 선택하거나 새 AAB를 업로드한다.

버전 이름:

```text
1.0.0
```

출시 노트:

```text
TeenPle initial Android release.
```

국가/지역을 선택한다.

권장:

- 처음에는 실제 서비스 대상 국가만 선택한다.
- 한국 서비스라면 Korea/South Korea 중심으로 시작한다.

`버전 검토`를 누른다.

모든 경고를 확인한다.

반드시 완료되어야 하는 항목:

- 스토어 등록정보 완료
- 앱 콘텐츠 완료
- 개인정보처리방침 완료
- 데이터 보안 완료
- 데이터 삭제 완료
- 앱 액세스 완료
- 콘텐츠 등급 완료
- 타겟층 완료
- AAB 업로드 완료
- 치명적인 출시 경고 없음

문제가 없으면:

```text
검토를 위해 제출
```

가능하면 관리형 게시를 켠다.

경로:

```text
게시 개요 -> 관리형 게시
```

권장:

```text
관리형 게시: 사용
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

- [ ] 앱 이름: TeenPle
- [ ] 기본 언어: 한국어
- [ ] 앱 유형: 앱
- [ ] 무료
- [ ] 스토어 등록정보 입력 완료
- [ ] 실제 심사 빌드 스크린샷 업로드
- [ ] 개인정보처리방침 URL 입력
- [ ] 광고: 아니요
- [ ] App access 심사용 계정 입력
- [ ] 타겟층 입력
- [ ] 콘텐츠 등급 완료
- [ ] 데이터 보안 완료
- [ ] 데이터 삭제 URL 입력
- [ ] UGC 신고/차단/moderation 설명 준비
- [ ] 내부 테스트 업로드 완료
- [ ] 출시 전 보고서 치명 이슈 없음
- [ ] 비공개 테스트 요구사항 확인
- [ ] 프로덕션 버전 검토 완료
- [ ] 검토를 위해 제출 완료

## 28. 반려를 피하기 위한 주의사항

아래 상태로 제출하지 않는다.

- 심사용 계정이 로그인되지 않음
- 심사용 계정이 학교 인증 대기 상태
- 심사용 계정이 정지/탈퇴 대기 상태
- 개인정보처리방침 URL 404
- 계정 삭제 URL 404
- 앱 안에는 계정 생성이 있는데 삭제 경로가 없음
- 데이터 보안에서 실제 수집 데이터를 누락
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
- 데이터 보안: https://support.google.com/googleplay/android-developer/answer/10787469
- Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- User generated content policy: https://support.google.com/googleplay/android-developer/answer/9876937
- Target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Personal account testing requirements: https://support.google.com/googleplay/android-developer/answer/14151465
