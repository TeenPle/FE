# Release Handoff Notes

Last updated: 2026-06-25

## Current Branch State

- The app now defaults to the deployed API:
  - `https://api.teenple.app`
- Review builds currently have ads disabled by default:
  - `ADS_ENABLED=false`
- Google Mobile Ads SDK and AdMob test IDs have been removed for the no-ads review build.
- Home and timetable onboarding code has been removed because those onboarding flows are not planned for release.

## Work Completed

### Backend/API connection

- Updated `lib/core/network/base_url.dart`.
- Debug and release builds now default to `https://api.teenple.app`.
- `API_BASE_URL` can still override the default at build time.

### Ads disabled for review

- Added `lib/core/config/feature_flags.dart`.
- `adsEnabled` defaults to `false`.
- Feed and post-detail ad slots do not reserve blank space when ads are disabled.
- `SchoolMainAdCard` returns `SizedBox.shrink()` when ads are disabled.
- Admin ad management entry point is hidden when ads are disabled.
- Direct `/admin/ads` route redirects to admin home when ads are disabled.

### AdMob removed from review build

- Removed `google_mobile_ads` from `pubspec.yaml`.
- Removed Google Mobile Ads entries from `pubspec.lock`.
- Removed AdMob test app IDs from:
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`
- Removed AdMob fallback/test banner code from `lib/core/widgets/school_main_ad_card.dart`.
- Removed `MobileAds.instance.initialize()` from `lib/main.dart`.

### Android release readiness

- Updated `android/app/build.gradle.kts`.
- Release builds now use `signingConfigs.getByName("release")`, not debug signing.
- Release build requires `android/key.properties`.
- Added `android/key.properties.example`.
- Added `.gitignore` entries for:
  - `android/key.properties`
  - `android/*.jks`
  - `android/*.keystore`
- Set `android:usesCleartextTraffic="false"` in main Android manifest.

### Onboarding removed

Deleted:

- `lib/core/services/onboarding_service.dart`
- `lib/features/school/pages/school_onboarding_page.dart`
- `lib/features/timetable/pages/timetable_onboarding_page.dart`

Removed:

- `tutorial_coach_mark` dependency.

### Unused dependencies removed

Removed direct dependencies that were not used by app code:

- `provider`
- `cupertino_icons`
- `http`

`http` remains available transitively through other packages where needed.

### Documentation added

- Added `docs/google_play_release_checklist.md`.
- Added this file: `docs/release_handoff.md`.

## Validation Already Run

```powershell
flutter pub get
flutter analyze
```

Result:

```text
No issues found
```

Additional release-risk searches were run for:

- debug release signing
- cleartext traffic in main manifest
- AdMob/test ad IDs
- Google Mobile Ads dependency
- onboarding/tutorial coach mark references
- obvious TODO/FIXME/mock/dummy/sample/print leftovers

No actionable matches remained.

## Known Environment Issue

Gradle verification could not be completed in the current shell environment.

Observed:

- Default `java -version` is `25.0.2`.
- Gradle/Kotlin DSL failed parsing Java version `25.0.2`.
- Retrying with Android Studio JBR 21 avoided that parse error, but the Gradle daemon exited without a useful error in this sandbox.

Next local build should use JDK 17 or Android Studio JBR 21, then run:

```powershell
flutter build appbundle --release
```

## Must Do Before Google Play Upload

1. Create the Android upload keystore.

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` from `android/key.properties.example`.

```properties
storeFile=../upload-keystore.jks
storePassword=your-keystore-password
keyAlias=upload
keyPassword=your-key-password
```

3. Keep the keystore and passwords out of Git.

4. Confirm `pubspec.yaml` version code has never been uploaded before.

```yaml
version: 1.0.0+1
```

If `+1` was already uploaded, increase it.

5. Build the AAB.

```powershell
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

6. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console Internal testing first.

7. Prepare reviewer account.

- Account must already be school verified.
- Reviewer should be able to access:
  - school feed
  - post detail
  - comments
  - report/block flows
  - settings/profile
  - account deletion path

8. Complete Play Console App content.

Focus areas:

- Privacy policy URL
- App access instructions
- Data Safety
- Account deletion
- UGC policy/reporting/moderation
- Content rating
- Target audience
- Ads declaration: current review build should be treated as no ads

9. If this is a new personal developer account created after 2023-11-13, complete Google Play closed testing requirements before production access.

## Important Product/Policy Notes

- The submitted build should not include screenshots showing ads.
- Do not build with `--dart-define=ADS_ENABLED=true` for the first no-ads review.
- If ads are reintroduced later:
  - add real AdMob IDs, not test IDs
  - restore/upgrade the ad SDK intentionally
  - update Play Console Ads declaration
  - update Data Safety if applicable
  - verify ATT/App Store privacy separately for iOS

## Files Most Relevant Next Time

- `docs/google_play_release_checklist.md`
- `docs/release_handoff.md`
- `android/app/build.gradle.kts`
- `android/key.properties.example`
- `lib/core/config/feature_flags.dart`
- `lib/core/network/base_url.dart`
- `lib/core/widgets/school_main_ad_card.dart`
- `lib/app/routes.dart`
- `lib/features/admin/pages/admin_home_page.dart`
