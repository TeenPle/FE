 # iOS Release Setup

## 1. Bundle Identifier

Xcode에서 `Runner` 타깃의 bundle identifier를 확정합니다.
현재 기본값은 `com.teenple.teenpleFrontend`입니다.
Firebase와 Apple Developer에 앱을 등록한 뒤에는 동일한 값을 유지해야 합니다.

## 2. Firebase

Firebase Console에서 iOS 앱을 추가하고 다음 파일을 로컬에 배치합니다.

```text
ios/Runner/GoogleService-Info.plist
```

FlutterFire CLI로 iOS 구성을 포함해 로컬 설정 파일을 다시 생성합니다.

```bash
flutterfire configure
```

생성되는 `lib/firebase_options.dart`와 `GoogleService-Info.plist`는 커밋하지 않습니다.

## 3. Push Notifications

Apple Developer에서 앱 ID의 Push Notifications capability를 활성화합니다.
APNs 인증 키를 발급해 Firebase Console의 Cloud Messaging 설정에 등록합니다.
Xcode의 `Runner` 타깃에서 Signing Team과 provisioning profile을 확인합니다.

저장소에는 다음 항목이 미리 반영되어 있습니다.

- Debug용 `Runner/Runner.entitlements`와 Profile·Release용
  `Runner/RunnerRelease.entitlements`의 `aps-environment`
- `Info.plist`의 `fetch`, `remote-notification` background modes

## 4. Verification

macOS에서 실제 기기로 디버그할 때는 iPhone에서 접근 가능한 HTTPS API 주소를 주입합니다.
`localhost`는 개발 PC가 아니라 iPhone 자신을 가리킵니다.

```bash
flutter run --dart-define=API_BASE_URL=https://your-test-api.example.com
```

실제 기기로 아래 항목을 확인합니다.

- 로그인 후 FCM 토큰 등록
- 포그라운드, 백그라운드, 종료 상태의 푸시 수신과 탭 이동
- 채팅 이미지 선택, HEIC 변환, 전송, 사진 보관함 저장
- 프로필, 학생증, 게시글 이미지 선택과 HEIC 변환
- 홈 인디케이터가 있는 기기에서 하단 내비게이션과 버튼 여백
- 작은 화면에서 로그인 키보드 표시 후 입력창과 로그인 버튼 접근
- 댓글, 문의 작성, 관리자 처리 화면에서 키보드 표시 후 하단 버튼 위치
- 시간표 메모, 시간표 수정, D-Day 편집 바텀시트의 하단 여백
- 세로 화면 고정과 다크 모드 표시
- `flutter build ipa --release`
