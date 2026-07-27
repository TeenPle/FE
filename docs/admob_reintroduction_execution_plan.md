# TeenPle AdMob 광고 재도입 실행 계획

작성일: 2026-07-26

## 1. 현재 상태 요약

TeenPle은 스토어 심사 대응을 위해 광고를 완전히 제거한 것이 아니라, 일부 광고 슬롯과 자체 광고 관리 기능은 남겨두고 노출만 비활성화한 상태다.

현재 기본 플래그:

```dart
// lib/core/config/feature_flags.dart
const bool adsEnabled = bool.fromEnvironment(
  'ADS_ENABLED',
  defaultValue: false,
);
```

현재 빌드 기본값은 `ADS_ENABLED=false`이므로 광고 UI가 표시되지 않는다.

현재 `pubspec.yaml`에는 `google_mobile_ads`가 없다. 즉, 지금 남아 있는 `SchoolMainAdCard`는 Google AdMob 광고가 아니라 백엔드에서 내려주는 자체/제휴 광고 배너 위젯이다.

심사 대응 당시 제거된 것:

- `google_mobile_ads` 의존성
- `pubspec.lock`의 Google Mobile Ads 관련 항목
- Android `AndroidManifest.xml`의 AdMob app ID
- iOS `Info.plist`의 `GADApplicationIdentifier`
- `MobileAds.instance.initialize()`
- AdMob 테스트 ID/테스트 배너 코드

근거 문서:

- `FE/docs/release_handoff.md`
- `FE/docs/google_play_release_checklist.md`
- `FE/docs/google_play_tomorrow_release_plan.md`

## 2. 기존 광고 코드 구조

### 2.1 프론트엔드

현재 광고 관련 FE 파일:

- `lib/core/config/feature_flags.dart`
- `lib/core/widgets/school_main_ad_card.dart`
- `lib/features/ad/api/ad_banner_api.dart`
- `lib/features/ad/provider/ad_banner_provider.dart`
- `lib/features/ad/models/ad_banner_model.dart`
- `lib/features/admin/pages/admin_ad_page.dart`
- `lib/features/admin/pages/admin_home_page.dart`
- `lib/app/routes.dart`
- `lib/features/school/pages/school_page.dart`
- `lib/features/post/pages/post_detail_page.dart`

현재 광고 슬롯:

1. 홈 피드
   - 파일: `lib/features/school/pages/school_page.dart`
   - 상수: `_homeFeedFirstAdAfterPosts = 5`
   - 조건: `adsEnabled && totalPostCount > _homeFeedFirstAdAfterPosts`
   - 위치: 게시글 목록에서 5개 게시글 이후 `SchoolMainAdCard()` 삽입

2. 게시글 상세
   - 파일: `lib/features/post/pages/post_detail_page.dart`
   - 조건: `if (adsEnabled)`
   - 위치: 게시글 본문, 투표, 액션바, 구분선 이후 / 댓글 섹션 헤더 이전
   - 현재 위젯: `SchoolMainAdCard(fullBleed: true, placement: 'POST_DETAIL')`

3. 관리자 광고 관리
   - 파일: `lib/features/admin/pages/admin_home_page.dart`
   - `adsEnabled`일 때만 광고 관리 메뉴 표시
   - 파일: `lib/app/routes.dart`
   - `/admin/ads` 직접 접근도 `adsEnabled=false`이면 관리자 홈으로 redirect

### 2.2 백엔드

현재 광고 관련 BE 파일:

- `domain/ad/controller/AdBannerController.java`
- `domain/ad/service/AdBannerService.java`
- `domain/ad/repository/AdBannerRepository.java`
- `domain/ad/entity/AdBanner.java`
- `domain/ad/enums/AdPlacement.java`
- `domain/ad/dto/AdBannerRequest.java`
- `domain/ad/dto/AdBannerResponse.java`

현재 API:

- `GET /api/ads/active?placement=HOME_FEED`
- `GET /api/ads/active?placement=POST_DETAIL`
- `GET /api/admin/ads`
- `POST /api/admin/ads`
- `PATCH /api/admin/ads/{adId}`
- `DELETE /api/admin/ads/{adId}`

현재 placement:

```java
public enum AdPlacement {
    HOME_FEED,
    POST_DETAIL
}
```

중요: 이 백엔드 광고 기능은 AdMob과 별개다. AdMob은 앱 클라이언트 SDK가 Google 서버에서 광고를 직접 로드하는 방식이므로, 현재 관리자 광고 관리 페이지로 AdMob 광고 소재를 직접 관리하는 구조가 아니다.

## 3. 결론: 어디에 다시 넣어야 하는가

가장 적절한 광고 위치는 기존 슬롯 2곳을 유지하는 것이다.

### 3.1 1순위: 홈 피드 게시글 5개 이후

위치:

- `lib/features/school/pages/school_page.dart`
- 기존 `SchoolMainAdCard()` 삽입 위치

이유:

- 피드 흐름 안에서 자연스럽다.
- 첫 화면 진입 직후 광고가 바로 뜨지 않아 사용자 경험이 덜 깨진다.
- 이미 `_homeFeedFirstAdAfterPosts = 5`로 과도한 상단 광고를 피하도록 설계되어 있다.

권장 광고 형식:

- AdMob Banner 또는 Anchored Adaptive Banner
- 네이티브 광고는 초기 재도입에서는 보류

### 3.2 2순위: 게시글 상세 댓글 영역 전

위치:

- `lib/features/post/pages/post_detail_page.dart`
- 기존 `SchoolMainAdCard(fullBleed: true, placement: 'POST_DETAIL')` 위치

이유:

- 본문 읽기와 반응 버튼 사용을 방해하지 않는다.
- 댓글 진입 전에 자연스럽게 한 번 노출된다.
- 입력창, 신고/차단, 댓글 액션과 겹치지 않는다.

권장 광고 형식:

- Banner 또는 Anchored Adaptive Banner
- 화면 하단 고정 배너는 댓글 입력창과 충돌 가능성이 있어 비추천

### 3.3 넣지 말아야 할 위치

초기 재도입에서는 아래 화면에 광고를 넣지 않는다.

- 로그인/회원가입
- 학교 검색/학교 인증/학생증 인증
- 인증 대기/거절 화면
- 채팅방/채팅 목록
- 신고/차단/계정 삭제/문의 작성
- 프로필 설정, 비밀번호 변경
- 관리자 화면

이유:

- 인증과 안전 기능은 TeenPle의 신뢰 핵심 흐름이다.
- 채팅과 신고/차단 화면은 광고로 사용자의 행동을 방해하면 안 된다.
- 청소년 대상 서비스이므로 광고 노출 밀도를 보수적으로 가져가야 한다.

## 4. 권장 구현 방향

현재 `SchoolMainAdCard`는 자체/제휴 광고 카드다. AdMob 실사용을 위해서는 이 위젯을 그대로 덮어쓰기보다 광고 타입을 분리하는 편이 안전하다.

권장 구조:

- `adsEnabled`: 광고 영역 전체 활성화 여부
- `admobEnabled`: Google AdMob 광고 활성화 여부
- `partnerAdsEnabled`: 기존 백엔드 제휴 배너 활성화 여부

예상 파일:

- `lib/core/config/feature_flags.dart`
- `lib/core/config/ad_config.dart`
- `lib/core/ads/admob_initializer.dart`
- `lib/core/widgets/admob_banner.dart`
- `lib/core/widgets/school_main_ad_card.dart`

권장 판단:

1. 실수익 광고가 목적이면 `AdMobBanner`를 우선 사용한다.
2. 자체 제휴 광고를 유지하려면 `PartnerAdCard`처럼 이름을 바꿔 의미를 분명히 한다.
3. 동일 슬롯에서 AdMob과 자체 광고를 동시에 보여주지 않는다.
4. 필요하면 우선순위를 둔다.
   - 예: 자체 제휴 광고가 있으면 자체 광고 노출
   - 없으면 AdMob fallback
   - 또는 반대로 AdMob만 사용

초기 운영 권장안:

- 1차 배포: AdMob만 홈 피드/게시글 상세 기존 슬롯에 노출
- 기존 관리자 광고 기능은 유지하되 기본적으로 숨김
- 자체 광고 영업/제휴를 실제로 시작할 때 별도 정책으로 다시 활성화

## 5. 코드 변경 계획

### 5.1 `pubspec.yaml`

추가:

```yaml
dependencies:
  google_mobile_ads: ^버전확인
```

주의:

- 실제 작업 시 최신 호환 버전은 `flutter pub add google_mobile_ads`로 추가한다.
- 현재 Flutter/Dart SDK와 충돌 없는지 `flutter pub get` 후 확인한다.

### 5.2 `feature_flags.dart`

현재:

```dart
const bool adsEnabled = bool.fromEnvironment(
  'ADS_ENABLED',
  defaultValue: false,
);
```

권장 추가:

```dart
const bool admobEnabled = bool.fromEnvironment(
  'ADMOB_ENABLED',
  defaultValue: false,
);

const bool partnerAdsEnabled = bool.fromEnvironment(
  'PARTNER_ADS_ENABLED',
  defaultValue: false,
);
```

정책:

- `ADS_ENABLED=false`이면 모든 광고 숨김
- `ADS_ENABLED=true && ADMOB_ENABLED=true`이면 AdMob 노출
- `ADS_ENABLED=true && PARTNER_ADS_ENABLED=true`이면 기존 백엔드 배너 노출
- 둘 다 true일 때 우선순위는 코드에서 명확히 고정

### 5.3 `ad_config.dart` 추가

역할:

- 플랫폼별 AdMob unit ID 관리
- release/debug 광고 ID 분리
- ID 누락 시 광고 로드하지 않도록 방어

권장:

- app ID는 Android/iOS 네이티브 설정에 필요하므로 manifest/plist에 들어간다.
- banner unit ID는 `--dart-define`으로 주입한다.
- AdMob ID는 비밀번호는 아니지만, 운영/테스트 혼동 방지를 위해 환경값으로 분리한다.

예상 값:

```powershell
--dart-define=ADS_ENABLED=true
--dart-define=ADMOB_ENABLED=true
--dart-define=ADMOB_ANDROID_HOME_BANNER_UNIT_ID=ca-app-pub-...
--dart-define=ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-...
--dart-define=ADMOB_IOS_HOME_BANNER_UNIT_ID=ca-app-pub-...
--dart-define=ADMOB_IOS_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-...
```

### 5.4 Android 설정

파일:

- `android/app/src/main/AndroidManifest.xml`

추가 위치:

- `<application>` 내부

필수 meta-data:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy" />
```

주의:

- `~`가 들어간 값은 AdMob app ID다.
- `/`가 들어간 값은 ad unit ID다.
- AndroidManifest에는 app ID가 들어가야 한다.
- 테스트 app ID를 프로덕션에 넣지 않는다.

### 5.5 iOS 설정

파일:

- `ios/Runner/Info.plist`

추가:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-################~##########</string>
```

주의:

- iOS도 app ID와 ad unit ID를 혼동하면 안 된다.
- 개인화 광고/IDFA를 사용하려면 ATT 관련 문구와 권한 흐름을 별도로 검토해야 한다.
- 초기에는 청소년 서비스 특성을 고려해 비개인화/제한적 광고 방향을 우선 검토한다.

### 5.6 `main.dart`

현재 `MobileAds.instance.initialize()`가 제거되어 있다.

권장:

1. Firebase 초기화 이후 또는 runApp 이전에 AdMob 초기화
2. 실제 광고 요청 전에 전역 광고 요청 설정 적용
3. `ADS_ENABLED && ADMOB_ENABLED`일 때만 초기화

초기화 순서 예:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(...);
if (adsEnabled && admobEnabled && _isMobile) {
  await initializeAdMob();
}
runApp(...);
```

청소년 대상 설정은 `initializeAdMob()` 내부에서 처리한다.

### 5.7 AdMob 배너 위젯 추가

새 파일 권장:

- `lib/core/widgets/admob_banner.dart`

책임:

- `BannerAd` 생성
- adaptive banner size 계산
- load 실패 시 `SizedBox.shrink()`
- dispose 처리
- 광고 로딩 중 빈 여백 최소화
- ad unit ID 없으면 로드하지 않음

권장 동작:

- debug/profile에서는 Google 공식 테스트 광고 ID 사용
- release에서는 실 unit ID만 사용
- release에서 unit ID가 비어 있으면 광고를 숨기고 로그만 남김
- 로드 실패 시 레이아웃을 무너뜨리지 않고 숨김

### 5.8 홈 피드 연결

파일:

- `lib/features/school/pages/school_page.dart`

현재:

```dart
item = const SchoolMainAdCard();
```

권장 변경:

```dart
item = const TeenpleAdSlot(placement: TeenpleAdPlacement.homeFeed);
```

또는 최소 변경:

```dart
item = const AdMobBanner(placement: AdMobPlacement.homeFeed);
```

단, 장기적으로는 `TeenpleAdSlot`처럼 슬롯 단위 위젯을 두는 편이 좋다.

### 5.9 게시글 상세 연결

파일:

- `lib/features/post/pages/post_detail_page.dart`

현재:

```dart
if (adsEnabled) ...[
  const SchoolMainAdCard(
    fullBleed: true,
    placement: 'POST_DETAIL',
  ),
  const SizedBox(height: 8),
],
```

권장 변경:

```dart
if (adsEnabled) ...[
  const TeenpleAdSlot(
    placement: TeenpleAdPlacement.postDetail,
    fullBleed: true,
  ),
  const SizedBox(height: 8),
],
```

주의:

- 댓글 입력창 하단 고정 영역과 겹치지 않도록 현재 위치 유지
- 댓글 목록 사이 반복 삽입은 초기에는 하지 않음

### 5.10 기존 자체 광고 위젯 처리

현재 `SchoolMainAdCard` 이름은 학교 메인 광고처럼 보이지만 실제로는 백엔드 제휴 광고다.

권장 리팩터링:

- `SchoolMainAdCard` -> `PartnerAdCard`
- 새 `TeenpleAdSlot`에서 다음처럼 선택:

```dart
if (!adsEnabled) return SizedBox.shrink();
if (partnerAdsEnabled) return PartnerAdCard(...);
if (admobEnabled) return AdMobBanner(...);
return SizedBox.shrink();
```

초기 구현에서 리팩터링 범위를 줄이고 싶다면:

- `SchoolMainAdCard`는 그대로 두고
- `AdMobBanner`만 만든 뒤 홈/상세 슬롯에서 `AdMobBanner`로 교체
- 자체 광고는 나중에 별도 이슈로 정리

## 6. AdMob/스토어 정책 체크리스트

### 6.1 Google Play Console

AdMob 광고를 실제 노출하면 Play Console에서 광고 포함 여부를 반드시 `예`로 변경해야 한다.

경로:

- Play Console
- 정책 및 프로그램
- 앱 콘텐츠
- 광고
- "앱에 광고가 포함되어 있나요?" -> `예`

Google 공식 Play Console Help는 앱 콘텐츠 페이지에서 광고 포함 여부, 개인정보처리방침, 대상 연령, 데이터 보안 등을 관리한다고 안내한다. 광고 SDK, 배너, 네이티브 광고, 자체 광고도 광고 포함 선언 대상이다.

### 6.2 데이터 보안

AdMob SDK를 다시 넣으면 데이터 보안 항목을 재검토해야 한다.

검토 항목:

- 기기 또는 기타 ID
- 앱 상호작용
- 대략적 위치 여부
- 진단/성능 데이터
- 광고 또는 마케팅 목적
- 분석 목적
- 제3자와 공유 여부

주의:

- 실제 수집 항목은 SDK 버전, AdMob 설정, 개인화 광고 여부, UMP/동의 설정에 따라 달라질 수 있다.
- Play Console 데이터 보안은 코드에 SDK가 들어간 사실뿐 아니라 실제 앱 동작과 정책 문서가 일치해야 한다.

### 6.3 개인정보처리방침

광고 재도입 전 개인정보처리방침에 아래 내용이 반영되어야 한다.

- Google AdMob 또는 Google Mobile Ads SDK 사용
- 광고 제공을 위한 기기 정보/광고 식별자 처리 가능성
- 개인화 광고 사용 여부
- 비개인화 광고 또는 청소년 보호 설정 적용 여부
- 제3자 SDK 제공자 명시
- 사용자가 문의할 수 있는 연락처

앱 내부와 스토어 등록정보의 개인정보처리방침 URL이 동일하게 최신 상태여야 한다.

### 6.4 청소년 대상 광고 설정

TeenPle은 고등학생 커뮤니티이므로 광고 설정을 일반 성인 앱처럼 두면 위험하다.

권장:

- 개인화 광고는 초기에는 사용하지 않는 방향으로 검토
- 선정적/도박/주류/성인/고위험 금융 등 민감 카테고리 차단
- 최대 광고 콘텐츠 등급을 보수적으로 설정
- AdMob 요청 설정에서 age treatment, max ad content rating 검토
- Google Play의 대상 연령 설정과 AdMob 요청 설정을 일치시킴

Google AdMob 공식 문서는 광고 요청에 전역 `RequestConfiguration`을 적용할 수 있고, 아동/청소년 처리와 최대 광고 콘텐츠 등급을 설정할 수 있다고 안내한다. 최신 Android 문서에서는 기존 TFCD/TFUA보다 age treatment 사용을 안내하고 있으므로 Flutter 플러그인에서 현재 지원하는 API를 확인해야 한다.

중요:

- TeenPle이 13세 미만을 대상으로 하지 않는다면 대상 연령을 무리하게 낮추지 않는다.
- 다만 고등학생 중 미성년자가 많으므로 광고 카테고리와 개인화 여부는 보수적으로 잡는다.
- 법적 판단이 필요한 영역은 운영자가 최종 확인해야 한다.

### 6.5 iOS App Store

iOS에도 AdMob을 붙이면 App Store Connect 개인정보 항목을 재검토해야 한다.

검토 항목:

- 광고 식별자 사용 여부
- 추적 여부
- ATT 권한 요청 필요 여부
- 앱 개인정보 라벨
- 개인정보처리방침

초기 권장:

- 개인화 광고/추적 기반 광고는 보류
- 비개인화 광고 중심으로 시작
- ATT가 필요한 설정을 넣는 경우 별도 심사 문구와 UX를 준비

## 7. AdMob 콘솔 준비사항

1. AdMob 계정 확인
2. Android 앱 등록
3. iOS 앱 등록
4. 앱 스토어 등록 앱과 AdMob 앱 연결
5. 광고 단위 생성
   - Android 홈 피드 배너
   - Android 게시글 상세 배너
   - iOS 홈 피드 배너
   - iOS 게시글 상세 배너
6. 광고 카테고리 차단 설정
7. 광고 콘텐츠 등급 설정
8. 결제/세금/본인 확인 상태 확인
9. `app-ads.txt` 필요 여부 확인
10. 실제 광고 송출 전 제한 상태 확인

사업자 여부:

- 일반적으로 앱에 공유 기능을 넣는 것처럼 AdMob SDK 연동 자체에 사업자가 필수는 아니다.
- 다만 광고 수익 정산, 세금 정보, 계정 유형, 지급 프로필은 AdMob/Google Payments 정책에 따라 정확히 설정해야 한다.
- 개인 개발자로 운영하는 경우에도 세금/지급 정보는 필요할 수 있다.

## 8. 빌드 플래그 설계

### 8.1 심사/운영 실수 방지 원칙

광고는 기본값을 계속 꺼둔다.

```dart
defaultValue: false
```

광고를 켤 때만 명시적으로 빌드한다.

예시:

```powershell
flutter build appbundle --release `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=ADMOB_ANDROID_HOME_BANNER_UNIT_ID=ca-app-pub-.../... `
  --dart-define=ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-.../...
```

iOS:

```powershell
flutter build ipa --release `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=ADMOB_IOS_HOME_BANNER_UNIT_ID=ca-app-pub-.../... `
  --dart-define=ADMOB_IOS_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-.../...
```

### 8.2 테스트 광고와 실광고 분리

정책:

- debug/profile: Google 공식 테스트 광고 ID만 사용
- release: 실 광고 unit ID만 사용
- release에서 테스트 ID가 발견되면 빌드 중단하는 검증 스크립트 추가 권장

검증 검색:

```powershell
rg -n "3940256099942544|test ad|TestAd|google_mobile_ads|ca-app-pub" lib android ios pubspec.yaml
```

단, release에서는 실 `ca-app-pub` 값이 manifest/plist에 들어갈 수 있으므로 테스트 publisher ID `3940256099942544` 중심으로 차단한다.

## 9. QA 계획

### 9.1 로컬/개발 테스트

확인 항목:

- `flutter pub get` 성공
- `flutter analyze` 성공
- Android debug 실행
- iOS debug 실행 가능하면 확인
- 광고 비활성 빌드에서 광고 영역이 전혀 보이지 않음
- 광고 활성 debug 빌드에서 테스트 광고가 정상 표시됨
- 홈 피드 게시글 5개 이하일 때 광고 없음
- 홈 피드 게시글 6개 이상일 때 5개 이후 광고 표시
- 게시글 상세에서 본문/액션바 이후, 댓글 이전 광고 표시
- 광고 로드 실패 시 빈 큰 공간이 남지 않음
- 네트워크 오류 시 앱 크래시 없음
- 화면 전환/새로고침/뒤로가기 반복 시 dispose 문제 없음
- 다크/라이트 테마에서 배경 깨짐 없음

### 9.2 정책 QA

확인 항목:

- Play Console 광고 선언 `예`
- 데이터 보안 최신화
- 개인정보처리방침 최신화
- 대상 연령/콘텐츠 등급 재확인
- AdMob 차단 카테고리 적용
- AdMob 앱 상태/광고 제한 상태 확인
- App Store Connect 개인정보 항목 재확인
- 스크린샷에 광고가 들어가는 경우 스토어 정책과 불일치 없음

### 9.3 릴리스 전 검색

```powershell
rg -n "ADS_ENABLED=true|ADMOB_ENABLED=true|3940256099942544|test ad|TestAd" lib android ios pubspec.yaml
rg -n "GADApplicationIdentifier|com.google.android.gms.ads.APPLICATION_ID|google_mobile_ads|ca-app-pub" lib android ios pubspec.yaml
```

목표:

- 테스트 광고 ID 없음
- 실 app ID는 AndroidManifest/Info.plist에만 명확히 존재
- 실 ad unit ID는 설정 파일 또는 dart-define 경로로만 관리
- 광고 플래그 기본값은 false 유지

## 10. 출시 순서

1. AdMob 콘솔에서 앱/광고 단위 생성
2. Play Console/App Store 개인정보/광고 정책 변경안 정리
3. 코드 작업
   - `google_mobile_ads` 추가
   - Android/iOS app ID 추가
   - feature flag 분리
   - AdMob initializer 추가
   - AdMob banner widget 추가
   - 홈 피드/게시글 상세 기존 슬롯 연결
4. debug 테스트 광고로 QA
5. release 빌드에서 실 광고 ID 적용
6. 내부 테스트 또는 비공개 테스트 트랙 업로드
7. 실제 기기에서 광고 표시/비표시/오류 케이스 확인
8. Play Console 광고 선언 및 데이터 보안 수정
9. 개인정보처리방침 업데이트
10. 프로덕션 점진 출시
11. 출시 후 crash, ANR, 광고 제한, 노출률, 사용자 반응 모니터링

## 11. 초기 운영 기준

광고 노출 밀도:

- 홈 피드: 게시글 5개 이후 1개
- 게시글 상세: 댓글 섹션 전 1개
- 댓글 사이 반복 광고 없음
- 전면 광고/interstitial 없음
- 리워드 광고 없음

광고 형식:

- 1차: 배너 또는 adaptive banner만
- 2차: 네이티브 광고는 별도 검토
- 초기에는 수익 극대화보다 심사 안정성/사용자 경험 우선

청소년 보호:

- 민감 카테고리 차단
- 콘텐츠 등급 보수 설정
- 개인화 광고 사용 여부 신중히 검토
- 사용자 신고/차단/인증 흐름에 광고 삽입 금지

## 12. 구현 시 주의할 점

1. `ADS_ENABLED=true`만 켰다고 AdMob이 동작하면 안 된다.
   - 자체 광고와 AdMob을 분리해야 한다.

2. `SchoolMainAdCard`는 이름과 실제 역할이 애매하다.
   - 지금은 백엔드 제휴 광고다.
   - AdMob 위젯과 혼동하지 않게 이름을 정리하는 것이 좋다.

3. Android/iOS app ID와 ad unit ID를 혼동하면 앱 크래시 또는 광고 미노출이 발생한다.
   - app ID: `ca-app-pub-...~...`
   - unit ID: `ca-app-pub-.../...`

4. release 빌드에 테스트 광고 ID가 들어가면 정책 리스크가 있다.

5. AdMob SDK 추가 후 Play Console에서 광고 없음으로 유지하면 선언 불일치가 된다.

6. 청소년 대상 서비스이므로 광고 카테고리와 개인화 광고 설정을 반드시 검토해야 한다.

7. 광고 로드 실패는 정상적인 운영 상황이다.
   - 실패 시 크래시가 나면 안 된다.
   - 큰 빈 공간을 남기면 안 된다.

8. 앱 최초 진입/로그인/인증 과정에 광고를 넣지 않는다.

9. 광고 재도입은 프로덕션 직행보다 내부 테스트 트랙에서 먼저 확인한다.

## 13. 참고 공식 문서

- Google Mobile Ads Flutter quick start: https://developers.google.com/admob/flutter/quick-start
- Flutter Google Mobile Ads cookbook: https://docs.flutter.dev/cookbook/plugins/google-mobile-ads
- Play Console App content / ads declaration: https://support.google.com/googleplay/android-developer/answer/9859455
- Google AdMob targeting and age treatment: https://developers.google.com/admob/android/targeting
- AdMob Families policy guide: https://support.google.com/admob/answer/6223431

## 14. 다음 실제 작업 체크리스트

- [ ] AdMob Android app ID 확보
- [ ] AdMob iOS app ID 확보
- [ ] Android 홈 피드 banner unit ID 확보
- [ ] Android 게시글 상세 banner unit ID 확보
- [ ] iOS 홈 피드 banner unit ID 확보
- [ ] iOS 게시글 상세 banner unit ID 확보
- [ ] AdMob 민감 카테고리 차단 설정
- [ ] 광고 콘텐츠 등급 설정
- [ ] `google_mobile_ads` 추가
- [ ] AndroidManifest app ID 추가
- [ ] Info.plist app ID 추가
- [ ] `admobEnabled`/`partnerAdsEnabled` 플래그 추가
- [ ] AdMob initializer 추가
- [ ] AdMob banner widget 추가
- [ ] 홈 피드 기존 광고 슬롯 연결
- [ ] 게시글 상세 기존 광고 슬롯 연결
- [ ] 광고 비활성 빌드 QA
- [ ] 테스트 광고 debug QA
- [ ] 실광고 release/internal test QA
- [ ] Play Console 광고 선언 `예` 변경
- [ ] Play Console 데이터 보안 갱신
- [ ] 개인정보처리방침 갱신
- [ ] App Store Connect 개인정보 항목 갱신
- [ ] 버전코드 증가 후 AAB/IPA 빌드
- [ ] 내부/비공개 테스트 업로드
- [ ] 프로덕션 점진 출시
