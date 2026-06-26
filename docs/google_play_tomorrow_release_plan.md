# Google Play 출시 작업 상세 실행 계획

작성일: 2026-06-25

이 문서는 AWS 공식 웹 페이지 배포가 끝난 뒤, 다음 날 Google Play Console에서 실제 심사 제출까지 진행하기 위한 실행 순서다.

공식 Google 문서 기준으로 확인한 핵심 요구사항:

- 새 앱과 앱 업데이트는 2025-08-31부터 Android 15, API 35 이상을 target 해야 한다.
- 앱에서 계정 생성을 허용하면 앱 내 계정 삭제 경로와 웹 계정 삭제 요청 링크가 모두 필요하다.
- Play Console의 Data safety 섹션에는 앱이 수집/공유/처리하는 데이터 정보를 실제 동작과 일치하게 입력해야 한다.
- 2023-11-13 이후 생성된 개인 개발자 계정은 프로덕션 출시 전 12명 이상이 14일 이상 참여하는 비공개 테스트 요건이 적용될 수 있다.

참고 공식 문서:

- Target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- New personal account testing requirements: https://support.google.com/googleplay/android-developer/answer/14151465
- Prepare app for review: https://support.google.com/googleplay/android-developer/answer/9859455
- Create and set up app: https://support.google.com/googleplay/android-developer/answer/9859152

## 0. 현재 작업 상태 요약

이미 완료된 FE 작업:

- 앱 기본 API: `https://api.teenple.app`
- 광고 비활성화:
  - `ADS_ENABLED=false`
  - 게시글 목록/상세에 광고 빈칸 없음
  - Google Mobile Ads SDK/test ID 제거
- release 빌드 서명 설정:
  - release build가 debug signing을 쓰지 않음
  - `android/key.properties` 없으면 release 빌드 실패하도록 설정
- 홈/시간표 온보딩 제거
- Notion 링크 제거
- 공식 웹 페이지 구현:
  - `web/terms/index.html`
  - `web/privacy/index.html`
  - `web/privacy-consent/index.html`
  - `web/support/index.html`
  - `web/account-deletion/index.html`
  - `web/legal-assets/teenple-terms.pdf`
  - `web/legal-assets/teenple-privacy.pdf`
- 앱의 약관/개인정보/문의하기는 공식 웹 URL을 외부 브라우저로 연다.
- 앱 내부 사용자용 문의 목록/작성/상세 화면은 제거했다.
- 백엔드 문의 API와 관리자 문의 기능은 유지한다.
- 백엔드 `SecurityConfig`에 공개 웹 경로 `permitAll()` 추가 완료:
  - `/`
  - `/terms`, `/terms/**`
  - `/privacy`, `/privacy/**`
  - `/privacy-consent`, `/privacy-consent/**`
  - `/support`, `/support/**`
  - `/account-deletion`, `/account-deletion/**`
  - `/legal-assets/**`
  - `/favicon.ico`

주의:

- 현재 변경분은 아직 커밋/푸시 전 로컬 변경 상태다.
- AWS 정적 웹 호스팅 작업 완료 후, URL이 실제로 열리는지 확인하고 나서 앱 빌드를 만드는 것이 좋다.

## 1. AWS 공식 웹 페이지 배포 완료 확인

AWS 작업은 `docs/aws_static_web_pages_setup.md`를 따라 완료한다.

배포 후 아래 URL이 모두 브라우저에서 열려야 한다.

```text
https://teenple.app/terms
https://teenple.app/privacy
https://teenple.app/privacy-consent
https://teenple.app/support
https://teenple.app/account-deletion
https://teenple.app/legal-assets/teenple-terms.pdf
https://teenple.app/legal-assets/teenple-privacy.pdf
```

PowerShell 확인:

```powershell
curl.exe -I https://teenple.app/terms
curl.exe -I https://teenple.app/privacy
curl.exe -I https://teenple.app/privacy-consent
curl.exe -I https://teenple.app/support
curl.exe -I https://teenple.app/account-deletion
curl.exe -I https://teenple.app/legal-assets/teenple-terms.pdf
curl.exe -I https://teenple.app/legal-assets/teenple-privacy.pdf
```

기대값:

```text
HTTP/2 200
```

브라우저에서 직접 확인할 것:

- 한글이 깨지지 않는다.
- `https://teenple.app/terms`처럼 `index.html` 없는 URL도 열린다.
- 개인정보처리방침 본문이 보인다.
- 이용약관 본문이 보인다.
- 문의하기 페이지에서 이메일 링크가 보인다.
- 계정 삭제 안내 페이지가 보인다.
- PDF 원문 링크가 열린다.
- `https://api.teenple.app` 기존 API가 깨지지 않았다.

이 단계가 실패하면 Play Console 입력 전에 먼저 AWS를 수정한다.

## 2. 백엔드 최종 확인

백엔드 경로:

```powershell
cd C:\develop\BE\backend
```

컴파일:

```powershell
.\gradlew.bat compileJava
```

기대값:

```text
BUILD SUCCESSFUL
```

확인할 것:

- 사용자 문의 API는 유지되어야 한다.
  - `/api/inquiries`
  - `/api/inquiries/{inquiryId}`
- 관리자 문의 API도 유지되어야 한다.
  - `/api/admin/inquiries`
  - `/api/admin/inquiries/{inquiryId}`
  - `/api/admin/inquiries/{inquiryId}/answer`
- 공개 웹 경로는 인증 없이 접근 가능해야 한다.
- 백엔드가 직접 HTML을 서빙하지 않아도 된다. 실제 정적 페이지는 S3/CloudFront가 담당한다.

백엔드 변경 파일:

```text
C:\develop\BE\backend\src\main\java\com\shu\backend\global\security\SecurityConfig.java
```

## 3. FE 코드 최종 확인

FE 경로:

```powershell
cd C:\develop\FE
```

기본 검증:

```powershell
flutter pub get
flutter analyze
```

확인 검색:

```powershell
rg -n "notion|Notion|www\.notion\.so" lib web
rg -n "AppRoutes\.inquiries|inquiryWrite|inquiryDetail\(" lib web
rg -n "google_mobile_ads|AdMob|ca-app-pub|test ad|TestAd" lib android ios pubspec.yaml
```

기대:

- Notion 링크 없음
- 사용자용 앱 내부 문의 라우트 없음
- Google Mobile Ads SDK/test ID 없음
- `flutter analyze` no issues

주의:

- `android/src/debug/AndroidManifest.xml`의 debug cleartext 설정은 debug 전용이라 심사 빌드에는 영향 없다.
- 심사용 release build는 `android/app/src/main/AndroidManifest.xml` 기준으로 `android:usesCleartextTraffic="false"`여야 한다.

## 4. Android release signing 준비

아직 keystore가 없다면 생성한다.

```powershell
cd C:\develop\FE
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties.example`을 참고해서 `android/key.properties`를 만든다.

```properties
storeFile=../upload-keystore.jks
storePassword=your-keystore-password
keyAlias=upload
keyPassword=your-key-password
```

절대 커밋하면 안 되는 파일:

```text
android/key.properties
android/*.jks
android/*.keystore
```

반드시 따로 백업할 것:

- `android/upload-keystore.jks`
- keystore password
- key password
- alias

업로드 키를 잃어버리면 이후 업데이트가 매우 번거로워진다.

## 5. 버전 확인

`pubspec.yaml` 확인:

```yaml
version: 1.0.0+1
```

의미:

- `1.0.0`: versionName
- `1`: versionCode

규칙:

- Play Console에 한 번이라도 업로드한 versionCode는 다시 사용할 수 없다.
- 내부 테스트에 올린 AAB도 versionCode를 소비한다.
- 이미 `+1`을 업로드했다면 반드시 올린다.

예:

```yaml
version: 1.0.1+2
```

## 6. Target SDK 확인

Google Play는 2025-08-31부터 새 앱과 업데이트에 Android 15, API 35 이상 target을 요구한다.

현재 Android 설정:

```text
android/app/build.gradle.kts
targetSdk = flutter.targetSdkVersion
compileSdk = flutter.compileSdkVersion
```

확인 방법:

```powershell
flutter doctor -v
flutter build appbundle --release
```

Play Console 업로드 후 target API 경고가 뜨면, Flutter SDK/Android Gradle 설정이 API 35 이상인지 확인해야 한다.

## 7. 심사용 AAB 빌드

FE 경로에서 실행:

```powershell
cd C:\develop\FE
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

성공 산출물:

```text
C:\develop\FE\build\app\outputs\bundle\release\app-release.aab
```

절대 사용하지 말 것:

```powershell
flutter build appbundle --release --dart-define=ADS_ENABLED=true
```

이번 심사 빌드는 광고 없음 상태로 제출한다.

## 8. release APK로 실기기 스모크 테스트

AAB는 직접 설치가 불편하므로 APK도 별도로 만들어 실기기 테스트한다.

```powershell
flutter build apk --release
```

APK 위치:

```text
C:\develop\FE\build\app\outputs\flutter-apk\app-release.apk
```

설치:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

테스트 체크리스트:

- 앱 실행 시 크래시 없음
- 로그인 성공
- 심사용 계정이 학교 인증 완료 상태
- 학교 피드 로딩
- 게시글 목록 로딩
- 게시글 상세 로딩
- 게시글 목록에 광고 빈칸 없음
- 게시글 상세에 광고 빈칸 없음
- 게시글 작성 가능
- 댓글 작성 가능
- 신고 기능 접근 가능
- 차단 기능 접근 가능
- 채팅 화면 접근 가능
- 급식 화면 접근 가능
- 시간표 화면 접근 가능
- 프로필 화면 접근 가능
- 설정 화면 접근 가능
- 문의하기 클릭 시 `https://teenple.app/support` 외부 브라우저로 열림
- 이용약관 클릭 시 `https://teenple.app/terms` 외부 브라우저로 열림
- 개인정보 수집·이용 동의 클릭 시 `https://teenple.app/privacy-consent` 외부 브라우저로 열림
- 개인정보처리방침 클릭 시 `https://teenple.app/privacy` 외부 브라우저로 열림
- 회원 탈퇴 화면 접근 가능
- 계정 삭제 안내 웹 URL이 별도로 열림
- 이미지 업로드 동작
- 푸시 알림 권한 요청 문구 자연스러움
- 네트워크 오류 상황에서 앱이 비정상 종료되지 않음

## 9. 심사용 계정 준비

Play 심사자가 막히면 반려될 가능성이 높다.

심사용 계정 조건:

- 이미 가입 완료
- 이메일/전화번호 인증 완료
- 학교 인증 완료
- 정지/제재 상태 아님
- 메인 피드 접근 가능
- 게시글/댓글/신고/차단/프로필/설정 확인 가능

Play Console App access에 넣을 내용 예시:

```text
Reviewer account:
Email: reviewer@example.com
Password: ********

This account is already school-verified.
After login, reviewers can access the school feed, post detail, comments, report/block flows, chat, profile/settings, and account deletion path.

Official web pages:
Privacy Policy: https://teenple.app/privacy
Privacy collection consent: https://teenple.app/privacy-consent
Terms: https://teenple.app/terms
Support: https://teenple.app/support
Account deletion: https://teenple.app/account-deletion
```

주의:

- 심사 기간 중 비밀번호를 바꾸지 않는다.
- 계정을 탈퇴/정지/삭제하지 않는다.
- 학교 인증 대기 상태 계정을 주면 안 된다.

## 10. Play Console 앱 생성/기본 설정

Play Console에서 새 앱 생성:

```text
App name: TeenPle
Default language: Korean
App or game: App
Free or paid: Free
```

필수 동의:

- Developer Program Policies
- US export laws declaration
- Play App Signing

앱 카테고리:

- 앱 성격에 맞게 선택
- 커뮤니티/소셜 성격이면 그에 맞는 카테고리 검토

연락처:

```text
Support email: teenple.official@gmail.com
Website: https://teenple.app/support
Privacy policy: https://teenple.app/privacy
```

## 11. Store Listing 준비

준비물:

- 앱 이름
- 짧은 설명, 80자 이하
- 자세한 설명, 4000자 이하
- 앱 아이콘
- 휴대전화 스크린샷
- Feature graphic
- 카테고리
- 태그
- 지원 이메일
- 웹사이트 URL
- 개인정보처리방침 URL

주의:

- 광고가 꺼진 심사 빌드이므로 스크린샷에도 광고 영역이 없어야 한다.
- 현재 숨겨진 기능을 설명에 쓰지 않는다.
- 과도한 키워드 반복 금지.
- 실제 앱 화면과 스크린샷이 달라 보이면 안 된다.

추천 입력 URL:

```text
Website: https://teenple.app/support
Privacy policy: https://teenple.app/privacy
```

## 12. App Content 입력

Play Console > Policy and programs > App content에서 아래를 완료한다.

필수 항목:

- Privacy Policy
- Ads
- App access
- Target audience and content
- Content rating
- Data safety
- Data deletion
- Sensitive permissions declarations, 표시되는 경우
- News app declaration, 표시되는 경우
- Government app declaration, 표시되는 경우

## 13. Ads 선언

이번 심사 빌드 기준:

```text
Ads: No
```

전제:

- 앱에 광고 SDK 없음
- 광고 지면 없음
- 광고 빈칸 없음
- `ADS_ENABLED=false`
- AdMob test ID 없음

나중에 실제 광고를 다시 넣으면 반드시 바꿔야 한다.

광고 재도입 시 해야 할 일:

- Google Mobile Ads SDK 재도입
- 실제 AdMob app ID/unit ID 적용
- 테스트 광고 ID 제거
- Play Console Ads 선언을 Yes로 변경
- Data safety 업데이트
- 스크린샷/심사 설명 업데이트

## 14. App Access 입력

심사자가 로그인 장벽에 막히지 않게 입력한다.

입력할 것:

- 로그인 이메일
- 비밀번호
- 이미 학교 인증 완료 상태라는 설명
- 주요 기능 접근 경로
- 문의/약관/개인정보/계정삭제 웹 URL
- 문제가 생기면 연락할 이메일

예시:

```text
Login is required to use the app.

Reviewer account:
Email: reviewer@example.com
Password: ********

The account is already school-verified.
After login, reviewers can access:
- School feed
- Posts and comments
- Report/block flows
- Chat
- Profile and settings
- Account deletion flow

Official URLs:
Privacy Policy: https://teenple.app/privacy
Terms: https://teenple.app/terms
Support: https://teenple.app/support
Account deletion: https://teenple.app/account-deletion

Contact: teenple.official@gmail.com
```

## 15. Target Audience and Content

TeenPle은 고등학생 대상 서비스 성격이 있으므로 신중하게 입력한다.

확인할 것:

- 실제 서비스 대상 연령
- 만 14세 이상 동의 문구
- 학생 인증 기반 서비스라는 설명
- 청소년 유해 콘텐츠 차단/신고/관리 정책
- 앱 내 UGC 존재 여부

주의:

- 아동 대상 앱으로 오인되지 않게 실제 대상과 정책을 정확히 입력한다.
- Play Console 질문에 따라 가족 정책 적용 여부를 신중히 판단한다.

## 16. Content Rating

콘텐츠 등급 설문에서 실제 기능대로 답한다.

TeenPle 관련 고려:

- 사용자 게시글 있음
- 댓글 있음
- 채팅 있음
- 신고/차단 있음
- 관리자 moderation 있음
- 학교 인증 기반 커뮤니티

허위로 낮게 입력하면 반려/정책 문제가 될 수 있다.

## 17. Data Safety 입력 준비

실제 앱 기준으로 입력해야 한다.

수집 가능성이 있는 데이터:

- 이름
- 이메일
- 전화번호
- 닉네임
- 성별
- 학년
- 학교명
- 학생증 인증 이미지
- 프로필 이미지
- 게시글
- 댓글
- 채팅 메시지
- 신고 내용
- 제재/경고 이력
- FCM push token
- 기기/OS 정보
- IP 주소
- 접속/이용 기록

목적:

- 계정 생성 및 로그인
- 학교 인증
- 서비스 제공
- 사용자 간 커뮤니케이션
- 신고 처리 및 moderation
- 부정 이용 방지
- 보안
- 알림 발송
- 계정 복구/탈퇴 처리

Data safety에서 특히 맞춰야 할 것:

- 개인정보처리방침 내용과 Play Console 답변이 일치해야 한다.
- 계정 삭제와 데이터 삭제 처리 방식이 웹 페이지와 일치해야 한다.
- 학생증 이미지는 인증 후 어떻게 보관/삭제하는지 실제 정책과 맞아야 한다.
- 광고 없음 빌드이면 광고 목적 데이터 수집으로 표시하지 않는다.

## 18. Data Deletion 입력

계정 생성이 있으므로 계정 삭제 요건을 만족해야 한다.

입력 URL:

```text
https://teenple.app/account-deletion
```

앱 내 경로:

```text
프로필 또는 설정 -> 회원 탈퇴
```

웹 페이지에서 확인되어야 하는 내용:

- TeenPle 계정 삭제 요청 방법
- 앱에서 삭제하는 방법
- 앱을 사용할 수 없을 때 이메일 요청 방법
- 7일 유예 기간
- 이후 개인정보 삭제
- 법령/운영정책상 보관될 수 있는 정보 안내

## 19. UGC 정책 대응

TeenPle은 UGC 앱이다.

심사 전 확인:

- 이용약관에 금지 콘텐츠/금지 행위가 있음
- 게시글 신고 가능
- 댓글 신고 가능
- 사용자 차단 가능
- 관리자 moderation 가능
- 제재/경고 기능 있음
- 청소년 보호 관련 문구 있음

심사 메모에 넣을 설명:

```text
TeenPle is a school-verified community app.
Users can create posts and comments, and can report inappropriate content.
Users can block other users.
Admins can review reports and moderate content/users.
```

## 20. 권한 선언 점검

AndroidManifest 주요 권한:

```text
INTERNET
POST_NOTIFICATIONS
READ_MEDIA_IMAGES
READ_EXTERNAL_STORAGE, maxSdkVersion=32
WRITE_EXTERNAL_STORAGE, maxSdkVersion=28
```

Play Console에서 권한 관련 질문이 나오면 실제 사용 목적대로 답한다.

설명 예:

- 사진/이미지 접근: 게시글 이미지, 프로필 이미지, 학생증 인증 이미지 업로드
- 알림: 댓글, 답글, 좋아요, 채팅, 경고/제재, 운영 알림
- 인터넷: 앱 서버 통신

## 21. 내부 테스트 업로드

Play Console:

```text
Test and release -> Testing -> Internal testing
```

순서:

1. Internal testing track 생성
2. 새 release 생성
3. `app-release.aab` 업로드
4. Release notes 입력
5. tester email 추가
6. publish internal test
7. tester link로 실제 기기 설치

확인할 것:

- 설치 가능
- 로그인 가능
- Play Protect/권한 경고 이상 없음
- Pre-launch report 생성 여부

## 22. Pre-launch Report 확인

Play Console에서 pre-launch report를 확인한다.

확인 항목:

- Crashes
- ANRs
- Accessibility warnings
- Security warnings
- Privacy warnings
- Unsupported device warnings
- Login failure
- Policy warnings
- Target API warnings

심사 제출 전 해결해야 하는 것:

- 크래시
- 로그인 불가
- 개인정보처리방침 URL 접근 불가
- 계정 삭제 URL 접근 불가
- Target API 오류
- 서명 오류
- 광고 선언 불일치

## 23. 비공개 테스트 요구사항 확인

개발자 계정이 개인 계정이고 2023-11-13 이후 생성됐다면, production 전에 비공개 테스트 요건이 적용될 수 있다.

필요할 수 있는 것:

- 12명 이상 tester
- 14일 이상 연속 참여
- 비공개 테스트 완료 후 production access 신청

내일 할 일:

- Play Console 계정 유형 확인
- Production 접근 가능 여부 확인
- 비공개 테스트 요구가 뜨면 production 제출이 아니라 closed testing 계획부터 진행

## 24. Production 제출

내부/비공개 테스트에서 문제가 없으면 production release를 만든다.

순서:

1. Test and release -> Production
2. Create new release
3. AAB 선택
4. Release notes 입력
5. 국가/지역 선택
6. 모든 warning 확인
7. App content 미완료 항목 없는지 확인
8. Store listing 미완료 항목 없는지 확인
9. Submit for review

권장:

```text
Managed publishing ON
```

이렇게 하면 승인 즉시 자동 출시되지 않고, 승인 후 수동으로 게시할 수 있다.

## 25. 내일 실제 작업 순서 요약

1. AWS 웹 페이지 URL 6개 200 확인
2. `api.teenple.app` 정상 확인
3. BE `compileJava` 확인
4. FE `flutter analyze` 확인
5. Notion/광고/삭제된 문의 라우트 검색 확인
6. release signing keystore 준비
7. `android/key.properties` 작성
8. `pubspec.yaml` versionCode 확인
9. `flutter build appbundle --release`
10. release APK 실기기 smoke test
11. Play Console 앱 생성
12. Store listing 입력
13. App content 입력
14. App access 심사용 계정 입력
15. Data safety 입력
16. Data deletion URL 입력
17. Internal testing 업로드
18. Pre-launch report 확인
19. 필요 시 closed testing 요건 확인
20. Production 제출 또는 closed testing 시작

## 26. 최종 제출 전 체크리스트

- [ ] `https://teenple.app/privacy` 열림
- [ ] `https://teenple.app/privacy-consent` 열림
- [ ] `https://teenple.app/terms` 열림
- [ ] `https://teenple.app/support` 열림
- [ ] `https://teenple.app/account-deletion` 열림
- [ ] PDF 원문 2개 열림
- [ ] `https://api.teenple.app` 정상
- [ ] BE `compileJava` 성공
- [ ] FE `flutter analyze` 성공
- [ ] `flutter build appbundle --release` 성공
- [ ] `app-release.aab` 생성됨
- [ ] release APK 실기기 설치/실행 성공
- [ ] 심사용 계정 로그인 성공
- [ ] 심사용 계정 학교 인증 완료
- [ ] 광고 영역 없음
- [ ] 광고 SDK/test ID 없음
- [ ] 문의하기는 웹으로 열림
- [ ] 개인정보처리방침은 웹으로 열림
- [ ] 이용약관은 웹으로 열림
- [ ] 계정 삭제 앱 내 경로 확인
- [ ] 계정 삭제 웹 URL 확인
- [ ] 게시글 신고 확인
- [ ] 댓글 신고 확인
- [ ] 사용자 차단 확인
- [ ] 관리자 moderation 가능 확인
- [ ] Store listing 입력 완료
- [ ] App content 입력 완료
- [ ] Data safety 입력 완료
- [ ] App access 입력 완료
- [ ] Content rating 완료
- [ ] Target audience 완료
- [ ] Ads 선언 No 확인
- [ ] Internal testing 업로드 완료
- [ ] Pre-launch report 치명 이슈 없음
- [ ] Production 또는 closed testing 다음 단계 결정
