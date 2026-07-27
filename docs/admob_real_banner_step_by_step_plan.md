# TeenPle 실제 AdMob 배너 광고 구현 상세 절차

작성일: 2026-07-26

## 0. 목표

현재 TeenPle에는 광고가 들어갈 위치 2개가 코드로 남아 있다.

1. 게시글 목록 피드
   - 게시글 5개 이후 1개
   - 파일: `lib/features/school/pages/school_page.dart`

2. 게시글 상세 페이지
   - 게시글 내용/액션바 아래, 댓글 영역 위
   - 파일: `lib/features/post/pages/post_detail_page.dart`

현재 이 위치에는 `SchoolMainAdCard`가 들어가지만, 이 위젯은 지금 Google AdMob이 아니라 백엔드에서 내려주는 자체/제휴 광고 배너다.

이번 작업의 목표는 기존 광고 위치 2개를 살려서 실제 Google AdMob 배너가 뜨도록 만드는 것이다.

## 1. 현재 코드 상태

### 1.1 광고 활성화 플래그

파일:

```text
lib/core/config/feature_flags.dart
```

현재:

```dart
const bool adsEnabled = bool.fromEnvironment(
  'ADS_ENABLED',
  defaultValue: false,
);
```

기본값이 `false`라서 일반 빌드에서는 광고가 표시되지 않는다.

### 1.2 목록 피드 광고 위치

파일:

```text
lib/features/school/pages/school_page.dart
```

현재 상수:

```dart
const int _homeFeedFirstAdAfterPosts = 5;
```

현재 삽입 로직:

```dart
final totalPostCount = hotPosts.length + feedPosts.length;
final showAdSlot =
    adsEnabled && totalPostCount > _homeFeedFirstAdAfterPosts;
final adInsertIndex = _homeFeedFirstAdAfterPosts;
final totalItemCount =
    totalPostCount + (showAdSlot ? 1 : 0) + 1; // +1 for footer
```

그리고 itemBuilder 내부:

```dart
} else if (showAdSlot && index == adInsertIndex) {
  item = const SchoolMainAdCard();
}
```

의미:

- 게시글이 6개 이상 있을 때 광고 슬롯이 생긴다.
- 인덱스 기준 5번 자리에 광고가 들어간다.
- 사용자가 보는 흐름상 게시글 5개를 본 뒤 광고가 나온다.

### 1.3 게시글 상세 광고 위치

파일:

```text
lib/features/post/pages/post_detail_page.dart
```

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

위치:

- `PostContentCard`
- 투표가 있으면 `PollCard`
- 구분선
- `PostActionBar`
- 구분선
- 광고
- 댓글 헤더
- 댓글 목록

즉 네가 기억한 것처럼 게시글 내용과 댓글 사이에 광고가 남아 있다.

### 1.4 현재 광고 위젯

파일:

```text
lib/core/widgets/school_main_ad_card.dart
```

현재 역할:

- `adsEnabled=false`이면 `SizedBox.shrink()`
- `activeAdProvider(placement)`로 백엔드 광고 조회
- 광고가 없거나 API 오류가 나면 `SizedBox.shrink()`
- 광고가 있으면 자체 카드 UI 표시

중요:

현재 이 파일에는 더 이상 아래 코드가 없다.

- `google_mobile_ads`
- `BannerAd`
- `AdWidget`
- `MobileAds.instance.initialize()`
- AdMob 테스트 광고 ID
- 실제 AdMob unit ID

## 2. 구현 방향 결정

### 2.1 기존 위치는 그대로 쓴다

광고 위치를 새로 만들지 않는다.

사용할 위치:

- 홈 피드: 기존 `SchoolMainAdCard()` 위치
- 게시글 상세: 기존 `SchoolMainAdCard(fullBleed: true, placement: 'POST_DETAIL')` 위치

이유:

- 이미 광고 비활성화 조건과 레이아웃 계산이 반영되어 있다.
- 심사 대응 당시 빈칸이 남지 않도록 정리된 구조다.
- 광고 재도입 시 가장 작은 변경으로 복구할 수 있다.

### 2.2 자체 광고와 AdMob을 분리한다

현재 `SchoolMainAdCard`는 이름이 애매하지만 실제로는 백엔드 제휴 광고다.

실제 AdMob 광고까지 이 파일에 다시 섞으면 나중에 혼동이 생긴다.

권장 구조:

```text
lib/core/widgets/admob_banner_ad.dart        // 실제 Google AdMob 배너
lib/core/widgets/teenple_ad_slot.dart        // 어떤 광고를 보여줄지 결정하는 슬롯
lib/core/widgets/school_main_ad_card.dart    // 기존 백엔드 제휴 광고 카드
```

역할:

- `AdMobBannerAd`: Google AdMob SDK만 담당
- `SchoolMainAdCard`: 백엔드 제휴 광고만 담당
- `TeenpleAdSlot`: 광고 위치별로 AdMob 또는 자체 광고를 선택

초기에는 AdMob만 쓸 것이므로 `TeenpleAdSlot`은 아래처럼 단순하게 시작해도 된다.

```dart
if (!adsEnabled) return const SizedBox.shrink();
if (admobEnabled) return AdMobBannerAd(...);
return const SizedBox.shrink();
```

## 3. AdMob 콘솔에서 먼저 준비할 것

코드 작업 전에 AdMob 콘솔에서 실제 ID를 만들어야 한다.

### 3.1 앱 등록

AdMob에서 앱을 등록한다.

필요:

- Android 앱
- iOS 앱

앱이 이미 Google Play/App Store에 출시되어 있으므로 스토어 앱과 연결한다.

### 3.2 광고 단위 생성

초기에는 배너 광고만 만든다.

필요한 광고 단위:

1. Android 홈 피드 배너
2. Android 게시글 상세 배너
3. iOS 홈 피드 배너
4. iOS 게시글 상세 배너

이렇게 4개를 분리하는 이유:

- 플랫폼별 성과를 따로 볼 수 있다.
- 홈 피드와 상세 페이지 수익/노출/클릭률을 따로 볼 수 있다.
- 문제가 생긴 지면만 끄거나 교체하기 쉽다.

### 3.3 ID 종류 구분

AdMob에는 app ID와 ad unit ID가 있다.

App ID:

```text
ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
```

Ad unit ID:

```text
ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

구분:

- `~`가 들어가면 app ID
- `/`가 들어가면 ad unit ID

사용 위치:

- AndroidManifest.xml: app ID
- Info.plist: app ID
- Dart 배너 로드 코드: ad unit ID

이걸 헷갈리면 앱 실행 시 크래시가 나거나 광고가 로드되지 않는다.

## 4. 패키지 추가

파일:

```text
pubspec.yaml
```

추가:

```yaml
dependencies:
  google_mobile_ads: ^8.0.0
```

실제 작업 시에는 직접 버전을 손으로 넣기보다 아래 명령을 권장한다.

```powershell
flutter pub add google_mobile_ads
```

이후:

```powershell
flutter pub get
```

확인:

```powershell
rg -n "google_mobile_ads" pubspec.yaml pubspec.lock
```

## 5. Feature Flag 정리

파일:

```text
lib/core/config/feature_flags.dart
```

현재 `adsEnabled`만 있다.

AdMob과 자체 광고를 분리하기 위해 아래를 추가한다.

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

최종 형태 예:

```dart
const bool adsEnabled = bool.fromEnvironment(
  'ADS_ENABLED',
  defaultValue: false,
);

const bool admobEnabled = bool.fromEnvironment(
  'ADMOB_ENABLED',
  defaultValue: false,
);

const bool partnerAdsEnabled = bool.fromEnvironment(
  'PARTNER_ADS_ENABLED',
  defaultValue: false,
);

const bool commentEditingEnabled = bool.fromEnvironment(
  'COMMENT_EDITING_ENABLED',
  defaultValue: false,
);

const bool postSharingEnabled = bool.fromEnvironment(
  'POST_SHARING_ENABLED',
  defaultValue: false,
);
```

운영 원칙:

- `ADS_ENABLED=false`: 어떤 광고도 노출하지 않음
- `ADS_ENABLED=true`, `ADMOB_ENABLED=true`: AdMob 노출
- `ADS_ENABLED=true`, `PARTNER_ADS_ENABLED=true`: 기존 백엔드 제휴 광고 노출
- 초기에는 `PARTNER_ADS_ENABLED=false` 권장

## 6. AdMob Unit ID 설정 파일 추가

새 파일:

```text
lib/core/config/admob_config.dart
```

역할:

- 플랫폼별 광고 unit ID 선택
- 홈 피드/게시글 상세 광고 unit ID 분리
- debug에서는 테스트 광고 ID 사용
- release에서는 dart-define으로 받은 실 광고 ID 사용
- ID가 비어 있으면 광고를 로드하지 않음

예시:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';

enum AdMobPlacement {
  homeFeed,
  postDetail,
}

class AdMobConfig {
  static const _androidHomeFeedUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_HOME_FEED_BANNER_UNIT_ID',
  );
  static const _androidPostDetailUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID',
  );
  static const _iosHomeFeedUnitId = String.fromEnvironment(
    'ADMOB_IOS_HOME_FEED_BANNER_UNIT_ID',
  );
  static const _iosPostDetailUnitId = String.fromEnvironment(
    'ADMOB_IOS_POST_DETAIL_BANNER_UNIT_ID',
  );

  static const _testBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  static String? bannerUnitId(AdMobPlacement placement) {
    if (!kReleaseMode) return _testBannerUnitId;

    final value = switch ((Platform.isAndroid, Platform.isIOS, placement)) {
      (true, false, AdMobPlacement.homeFeed) => _androidHomeFeedUnitId,
      (true, false, AdMobPlacement.postDetail) => _androidPostDetailUnitId,
      (false, true, AdMobPlacement.homeFeed) => _iosHomeFeedUnitId,
      (false, true, AdMobPlacement.postDetail) => _iosPostDetailUnitId,
      _ => '',
    };

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
```

주의:

- 테스트 광고 ID `3940256099942544`는 debug/profile에서만 사용한다.
- release 빌드에서 테스트 광고 ID가 들어가면 안 된다.
- ad unit ID는 비밀키는 아니지만, 실수 방지를 위해 dart-define으로 분리한다.

## 7. AndroidManifest 설정

파일:

```text
android/app/src/main/AndroidManifest.xml
```

`<application>` 안에 추가:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy" />
```

위치는 기존 Firebase meta-data 근처가 적절하다.

예:

```xml
<application
    android:label="TeenPle"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="false">

    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy" />

    ...
</application>
```

주의:

- 여기는 `~`가 들어간 Android AdMob app ID를 넣는다.
- `/`가 들어간 ad unit ID를 넣으면 안 된다.
- 테스트 app ID를 운영에 넣지 않는다.

## 8. iOS Info.plist 설정

파일:

```text
ios/Runner/Info.plist
```

`<dict>` 내부에 추가:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-################~##########</string>
```

주의:

- 여기도 `~`가 들어간 iOS AdMob app ID를 넣는다.
- Android app ID와 iOS app ID는 보통 다르다.
- 개인화 광고/IDFA를 사용할 경우 ATT 문구와 App Store privacy 설정을 별도로 검토해야 한다.

## 9. AdMob 초기화 추가

파일:

```text
lib/main.dart
```

추가 import:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/config/feature_flags.dart';
```

현재 `main()` 흐름:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ...
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ...
  runApp(const ProviderScope(child: TeenpleApp()));
}
```

Firebase 초기화 이후, `runApp` 이전에 AdMob 초기화:

```dart
if (_isMobile && adsEnabled && admobEnabled) {
  await MobileAds.instance.initialize();
}
```

최종 위치 예:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

if (_isMobile && adsEnabled && admobEnabled) {
  await MobileAds.instance.initialize();
}

if (_isMobile) {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
```

청소년 대상 설정까지 반영하려면 `MobileAds.instance.initialize()` 전에 `MobileAds.instance.updateRequestConfiguration(...)`를 넣는 구조를 검토한다.

예상:

```dart
await MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(
    maxAdContentRating: MaxAdContentRating.g,
  ),
);
await MobileAds.instance.initialize();
```

주의:

- 실제 사용할 수 있는 API 이름은 설치한 `google_mobile_ads` 버전에 맞춰 확인해야 한다.
- TeenPle은 고등학생 대상이므로 광고 콘텐츠 등급을 보수적으로 잡는 것이 좋다.

## 10. 실제 AdMob 배너 위젯 추가

새 파일:

```text
lib/core/widgets/admob_banner_ad.dart
```

역할:

- AdMob placement를 받는다.
- 광고 unit ID를 가져온다.
- `BannerAd`를 생성하고 로드한다.
- 로딩 실패 시 조용히 숨긴다.
- 위젯 dispose 시 광고 객체를 dispose한다.

초기 구현 예:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';

class AdMobBannerAd extends StatefulWidget {
  final AdMobPlacement placement;
  final bool fullBleed;

  const AdMobBannerAd({
    super.key,
    required this.placement,
    this.fullBleed = false,
  });

  @override
  State<AdMobBannerAd> createState() => _AdMobBannerAdState();
}

class _AdMobBannerAdState extends State<AdMobBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final adUnitId = AdMobConfig.bannerUnitId(widget.placement);
    if (adUnitId == null) return;

    final size = widget.placement == AdMobPlacement.postDetail
        ? AdSize.mediumRectangle
        : AdSize.banner;

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            debugPrint(
              '[AdMob] failed to load ${widget.placement}: '
              '${error.code} ${error.message}',
            );
          }
        },
      ),
    );

    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: widget.fullBleed
          ? const EdgeInsets.symmetric(vertical: 12)
          : const EdgeInsets.fromLTRB(18, 12, 18, 12),
      alignment: Alignment.center,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
```

개선 가능:

- 홈 피드는 `AdSize.banner` 대신 `AdSize.largeBanner` 또는 adaptive banner 검토
- 상세는 기존 구현처럼 `AdSize.mediumRectangle` 유지 가능
- 다만 초기에는 너무 큰 광고보다 일반 배너가 사용자 경험상 더 안전하다.

## 11. 광고 슬롯 위젯 추가

새 파일:

```text
lib/core/widgets/teenple_ad_slot.dart
```

역할:

- `adsEnabled` 확인
- `admobEnabled` 확인
- 필요하면 `partnerAdsEnabled` 확인
- 실제 광고 위젯 선택

초기 구현 예:

```dart
import 'package:flutter/material.dart';

import '../config/admob_config.dart';
import '../config/feature_flags.dart';
import 'admob_banner_ad.dart';
import 'school_main_ad_card.dart';

class TeenpleAdSlot extends StatelessWidget {
  final AdMobPlacement placement;
  final bool fullBleed;

  const TeenpleAdSlot({
    super.key,
    required this.placement,
    this.fullBleed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!adsEnabled) return const SizedBox.shrink();

    if (admobEnabled) {
      return AdMobBannerAd(
        placement: placement,
        fullBleed: fullBleed,
      );
    }

    if (partnerAdsEnabled) {
      return SchoolMainAdCard(
        fullBleed: fullBleed,
        placement: placement == AdMobPlacement.postDetail
            ? 'POST_DETAIL'
            : 'HOME_FEED',
      );
    }

    return const SizedBox.shrink();
  }
}
```

초기 운영 추천:

- `ADS_ENABLED=true`
- `ADMOB_ENABLED=true`
- `PARTNER_ADS_ENABLED=false`

## 12. 목록 피드에 AdMob 연결

파일:

```text
lib/features/school/pages/school_page.dart
```

기존 import:

```dart
import '../../../core/widgets/school_main_ad_card.dart';
```

변경:

```dart
import '../../../core/config/admob_config.dart';
import '../../../core/widgets/teenple_ad_slot.dart';
```

기존:

```dart
} else if (showAdSlot && index == adInsertIndex) {
  item = const SchoolMainAdCard();
}
```

변경:

```dart
} else if (showAdSlot && index == adInsertIndex) {
  item = const TeenpleAdSlot(
    placement: AdMobPlacement.homeFeed,
  );
}
```

유지할 것:

```dart
const int _homeFeedFirstAdAfterPosts = 5;
```

이 값은 지금 코드와 Git 히스토리상 AdMob 추가 당시에도 5였으므로 그대로 둔다.

## 13. 게시글 상세에 AdMob 연결

파일:

```text
lib/features/post/pages/post_detail_page.dart
```

기존 import:

```dart
import '../../../core/widgets/school_main_ad_card.dart';
```

변경:

```dart
import '../../../core/config/admob_config.dart';
import '../../../core/widgets/teenple_ad_slot.dart';
```

기존:

```dart
if (adsEnabled) ...[
  const SchoolMainAdCard(
    fullBleed: true,
    placement: 'POST_DETAIL',
  ),
  const SizedBox(height: 8),
],
```

변경:

```dart
if (adsEnabled) ...[
  const TeenpleAdSlot(
    fullBleed: true,
    placement: AdMobPlacement.postDetail,
  ),
  const SizedBox(height: 8),
],
```

광고 위치는 그대로 유지한다.

## 14. 기존 `SchoolMainAdCard` 처리

초기 작업에서는 삭제하지 않는다.

이유:

- 백엔드 광고 API와 관리자 광고 관리 페이지가 이미 있다.
- 나중에 제휴 광고를 직접 운영할 가능성이 있다.
- 지금 삭제하면 변경 범위가 커진다.

다만 역할은 명확히 기억한다.

```text
SchoolMainAdCard = 백엔드 제휴 광고 카드
AdMobBannerAd = Google AdMob 실제 배너
TeenpleAdSlot = 광고 지면 선택기
```

나중에 정리한다면:

```text
SchoolMainAdCard -> PartnerAdCard
```

로 이름을 바꾸는 것이 좋다.

## 15. 빌드 방법

### 15.1 광고 꺼진 기본 빌드

광고를 끈 빌드는 dart-define 없이 빌드한다.

```powershell
flutter build appbundle --release
```

이 경우:

- `ADS_ENABLED=false`
- 광고 없음
- AdMob 초기화 안 함
- 광고 슬롯 표시 안 함

### 15.2 Android AdMob 활성 빌드

예:

```powershell
flutter build appbundle --release `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=PARTNER_ADS_ENABLED=false `
  --dart-define=ADMOB_ANDROID_HOME_FEED_BANNER_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy `
  --dart-define=ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

주의:

- Android 빌드에는 Android unit ID만 필요하다.
- iOS unit ID는 iOS 빌드 때 넣는다.
- AndroidManifest에는 Android app ID가 이미 들어가 있어야 한다.

### 15.3 iOS AdMob 활성 빌드

예:

```powershell
flutter build ipa --release `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=PARTNER_ADS_ENABLED=false `
  --dart-define=ADMOB_IOS_HOME_FEED_BANNER_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy `
  --dart-define=ADMOB_IOS_POST_DETAIL_BANNER_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

주의:

- Info.plist에는 iOS app ID가 들어가 있어야 한다.
- iOS 개인정보/ATT 설정은 별도 확인한다.

## 16. 코드 검증 순서

### 16.1 정적 분석

```powershell
flutter pub get
flutter analyze
```

### 16.2 광고 관련 검색

```powershell
rg -n "google_mobile_ads|MobileAds|BannerAd|AdWidget|GADApplicationIdentifier|APPLICATION_ID|ca-app-pub" lib android ios pubspec.yaml
```

확인할 것:

- `google_mobile_ads`가 pubspec에 있다.
- `MobileAds.instance.initialize()`가 main.dart에 있다.
- AndroidManifest에 app ID가 있다.
- Info.plist에 app ID가 있다.
- Dart 코드에는 ad unit ID가 직접 하드코딩되어 있지 않거나, 테스트 ID는 debug에서만 사용한다.

### 16.3 테스트 광고 ID 검색

```powershell
rg -n "3940256099942544" lib android ios pubspec.yaml
```

허용:

- `admob_config.dart`에서 debug용 테스트 unit ID로만 존재

금지:

- AndroidManifest release app ID에 테스트 ID 사용
- Info.plist release app ID에 테스트 ID 사용
- release에서 테스트 unit ID가 선택되는 구조

## 17. 기능 QA

### 17.1 광고 꺼진 상태

빌드:

```powershell
flutter run
```

또는 release 기본 빌드.

확인:

- 홈 피드에 광고 공간 없음
- 게시글 상세에 광고 공간 없음
- 관리자 광고 메뉴는 기존 조건대로 숨김 또는 의도한 대로 동작
- 앱 크래시 없음

### 17.2 debug 테스트 광고

빌드:

```powershell
flutter run `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true
```

확인:

- 홈 피드에서 게시글 5개 이후 테스트 광고 표시
- 게시글이 5개 이하이면 홈 피드 광고 없음
- 게시글 상세에서 본문/액션바 아래, 댓글 위에 테스트 광고 표시
- 화면 전환 후 다시 들어와도 광고 dispose 오류 없음
- 광고 로딩 실패 시 빈 큰 공간이 남지 않음
- 다크모드/라이트모드 배경 깨짐 없음

### 17.3 release 내부 테스트

빌드:

```powershell
flutter build appbundle --release `
  --dart-define=ADS_ENABLED=true `
  --dart-define=ADMOB_ENABLED=true `
  --dart-define=PARTNER_ADS_ENABLED=false `
  --dart-define=ADMOB_ANDROID_HOME_FEED_BANNER_UNIT_ID=실제값 `
  --dart-define=ADMOB_ANDROID_POST_DETAIL_BANNER_UNIT_ID=실제값
```

확인:

- AAB 업로드 전 versionCode 증가
- 내부 테스트 트랙 업로드
- 실제 설치 후 홈 피드/상세 광고 위치 확인
- 광고가 바로 안 뜨는 경우 AdMob 승인/제한/노출 지연 상태 확인
- 앱 크래시/ANR 확인

## 18. Play Console 설정

AdMob 광고가 들어간 빌드를 출시하려면 Play Console 설정을 반드시 바꾼다.

### 18.1 광고 선언

경로:

```text
Play Console > 정책 및 프로그램 > 앱 콘텐츠 > 광고
```

답변:

```text
앱에 광고가 포함되어 있나요? -> 예
```

현재 광고 없음으로 제출했던 설정을 그대로 두면 정책 불일치가 된다.

### 18.2 데이터 보안

경로:

```text
Play Console > 정책 및 프로그램 > 앱 콘텐츠 > 데이터 보안
```

AdMob SDK 추가로 인해 다시 검토할 항목:

- 기기 또는 기타 ID
- 앱 상호작용
- 진단
- 광고 또는 마케팅 목적
- 분석 목적
- 제3자와 공유 여부

실제 답변은 AdMob 설정, 개인화 광고 여부, SDK 버전에 따라 달라질 수 있으므로 Google Mobile Ads SDK 데이터 공개 문서를 기준으로 확인한다.

### 18.3 개인정보처리방침

개인정보처리방침에 아래 내용을 반영한다.

- Google AdMob 사용
- Google Mobile Ads SDK 사용
- 광고 제공을 위한 기기 정보 또는 광고 식별자 처리 가능성
- 개인화 광고 사용 여부
- 청소년 보호를 위한 광고 제한 설정
- 제3자 SDK 제공자

## 19. App Store Connect 설정

iOS에도 광고를 넣으면 App Store Connect 개인정보 항목을 다시 확인한다.

검토:

- 광고 목적 데이터 수집 여부
- 추적 여부
- IDFA 사용 여부
- ATT 권한 필요 여부
- 개인정보 라벨

초기 권장:

- 개인화 광고는 보류
- 비개인화/제한 광고 중심으로 시작
- ATT가 필요한 구조는 별도 문서로 검토 후 적용

## 20. 청소년 서비스 관점 주의사항

TeenPle은 고등학생 대상 커뮤니티다.

광고 재도입 시 가장 중요한 것은 수익보다 심사 안정성과 사용자 신뢰다.

권장:

- 전면 광고 사용하지 않음
- 리워드 광고 사용하지 않음
- 댓글 사이 반복 광고 사용하지 않음
- 홈 피드 1개, 상세 1개로 시작
- 선정적/도박/주류/성인/고위험 금융 광고 차단
- 광고 콘텐츠 등급 보수 설정
- 개인화 광고 사용 여부 신중히 검토

초기 노출 정책:

```text
홈 피드: 게시글 5개 이후 1개
게시글 상세: 본문과 댓글 사이 1개
그 외 화면: 광고 없음
```

## 21. 출시 전 최종 체크리스트

- [ ] AdMob Android app ID 확보
- [ ] AdMob iOS app ID 확보
- [ ] Android 홈 피드 ad unit ID 확보
- [ ] Android 게시글 상세 ad unit ID 확보
- [ ] iOS 홈 피드 ad unit ID 확보
- [ ] iOS 게시글 상세 ad unit ID 확보
- [ ] `google_mobile_ads` 추가
- [ ] `feature_flags.dart`에 `admobEnabled` 추가
- [ ] `feature_flags.dart`에 `partnerAdsEnabled` 추가
- [ ] `admob_config.dart` 추가
- [ ] `admob_banner_ad.dart` 추가
- [ ] `teenple_ad_slot.dart` 추가
- [ ] AndroidManifest에 Android app ID 추가
- [ ] Info.plist에 iOS app ID 추가
- [ ] main.dart에 `MobileAds.instance.initialize()` 추가
- [ ] 홈 피드 기존 광고 위치를 `TeenpleAdSlot`으로 교체
- [ ] 게시글 상세 기존 광고 위치를 `TeenpleAdSlot`으로 교체
- [ ] `flutter pub get` 성공
- [ ] `flutter analyze` 성공
- [ ] debug 테스트 광고 표시 확인
- [ ] 광고 꺼진 빌드에서 광고 공간 없음 확인
- [ ] release 내부 테스트에서 실 광고 또는 AdMob 상태 확인
- [ ] Play Console 광고 선언 `예` 변경
- [ ] Play Console 데이터 보안 갱신
- [ ] 개인정보처리방침 갱신
- [ ] App Store Connect 개인정보 항목 갱신
- [ ] versionCode/build number 증가
- [ ] 내부 테스트 업로드
- [ ] 프로덕션 점진 출시

## 22. 실제 작업 순서 요약

1. AdMob에서 앱과 광고 단위 4개 생성
2. Android/iOS app ID 확보
3. Android/iOS ad unit ID 확보
4. `google_mobile_ads` 추가
5. AndroidManifest/Info.plist에 app ID 추가
6. `feature_flags.dart`에 AdMob 플래그 추가
7. `admob_config.dart` 작성
8. `admob_banner_ad.dart` 작성
9. `teenple_ad_slot.dart` 작성
10. 홈 피드 기존 `SchoolMainAdCard()`를 `TeenpleAdSlot(homeFeed)`로 교체
11. 상세 기존 `SchoolMainAdCard(POST_DETAIL)`를 `TeenpleAdSlot(postDetail)`로 교체
12. `main.dart`에 AdMob 초기화 추가
13. debug 테스트 광고 확인
14. release 내부 테스트 빌드 확인
15. Play Console/App Store 정책 항목 업데이트
16. 프로덕션 출시

## 23. 참고

기존 AdMob 구현 히스토리:

- `1488121 Feat: add google admob`
- `365baf9 chore: prepare Play Store review release`

`1488121`에서는 `google_mobile_ads`, `BannerAd`, `AdWidget`, 테스트 광고 fallback이 있었다.

`365baf9`에서 심사 대응을 위해 제거된 것:

- `google_mobile_ads`
- `MobileAds.instance.initialize()`
- Android/iOS AdMob test app ID
- `SchoolMainAdCard` 내부 AdMob fallback/test banner

따라서 이번 작업은 과거 테스트 광고 fallback을 그대로 되살리는 것이 아니라, 기존 위치만 살리고 실제 운영용 AdMob 구조로 다시 붙이는 작업이다.
