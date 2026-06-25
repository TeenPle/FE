# Google Play Release Checklist

Last reviewed: 2026-06-25

This checklist is for releasing TeenPle to Google Play. Complete it in order.

## 1. Code Readiness

- Pull the latest release source.

```powershell
git switch main
git fetch origin
git pull origin main
flutter clean
flutter pub get
flutter analyze
```

- Confirm the production API is used by default.
  - `lib/core/network/base_url.dart` should default to `https://api.teenple.app`.
  - Do not pass a local `API_BASE_URL` when building for review.

- Confirm ads are disabled for the review build.
  - `ADS_ENABLED` defaults to `false`.
  - Do not build with `--dart-define=ADS_ENABLED=true`.
  - The current review build removes the Google Mobile Ads SDK and test ad IDs.

- Confirm no release build uses debug signing.
  - `android/app/build.gradle.kts` must use `signingConfigs.getByName("release")`.
  - `android/key.properties` must exist locally before building release artifacts.

## 2. Android Release Signing

Create an upload keystore if one does not already exist.

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` from `android/key.properties.example`.

```properties
storeFile=../upload-keystore.jks
storePassword=your-keystore-password
keyAlias=upload
keyPassword=your-key-password
```

Do not commit:

- `android/key.properties`
- `android/*.jks`
- `android/*.keystore`

Back up the upload keystore and passwords in a secure password manager. Losing the upload key makes future updates harder.

## 3. Versioning

Check `pubspec.yaml`.

```yaml
version: 1.0.0+1
```

- `1.0.0` is `versionName`.
- `1` is `versionCode`.
- Each uploaded Play artifact must use a new, higher `versionCode`.
- If Play Console already received `+1`, increase it before building, for example:

```yaml
version: 1.0.1+2
```

## 4. Target API Requirement

Google Play requires new apps and app updates submitted after 2025-08-31 to target Android 15, API level 35, or higher.

Before uploading, verify Play Console does not report a target API error. If it does, update Flutter/Android Gradle config so `targetSdkVersion` is API 35 or higher.

## 5. Build The App Bundle

Run:

```powershell
flutter build appbundle --release
```

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Do not use this for the first review build:

```powershell
flutter build appbundle --release --dart-define=ADS_ENABLED=true
```

## 6. Local Device Smoke Test

Install and test a release build before upload.

Recommended checks:

- App launches without crash.
- Login works with a real approved review/test account.
- Signup works, including email/phone/school flows if enabled.
- School feed loads from `https://api.teenple.app`.
- Post list has no ad gap.
- Post detail has no ad gap.
- Post create/edit/delete works.
- Comment create/edit/delete works.
- Report post and report comment work.
- Block user works.
- Profile page and settings open.
- Account deletion path is visible and works or starts a deletion request.
- Image upload works.
- Push notification permission request is understandable.
- App behaves reasonably with network errors.

## 7. Play Console App Setup

In Play Console:

- Create app.
- Default language: Korean, unless a different launch language is intended.
- App type: App.
- Free or paid: Free.
- App name: `TeenPle`.
- Contact email: a monitored support email.
- Accept Developer Program Policies.
- Accept US export laws declaration.
- Accept Play App Signing terms.

## 8. Store Listing

Prepare:

- App name, 30 characters max.
- Short description, 80 characters max.
- Full description, 4000 characters max.
- App icon.
- Phone screenshots.
- Feature graphic.
- Category and tags.
- Support email.
- Website URL if available.
- Privacy policy URL.

Rules:

- Screenshots must match the review build.
- Do not show ad slots in screenshots for the no-ads review build.
- Do not overuse repeated keywords.
- Do not describe features that are hidden or unavailable to reviewers.

## 9. App Content Declarations

Go to Play Console > Policy and programs > App content.

Complete:

- Privacy Policy.
- Ads.
- App access.
- Target audience and content.
- Content rating questionnaire.
- Data safety.
- Data deletion.
- Sensitive permissions declarations, if prompted.
- News app declaration, if prompted.
- Government app declaration, if prompted.

For the current review build, Ads should be answered as no ads only if the submitted binary does not include active ad serving or ad placements.

## 10. Privacy Policy

The privacy policy must be reachable from:

- Play Store listing.
- Inside the app.

It should cover:

- Account data: login ID, email, phone number, nickname.
- School verification data: school, grade/class/number, student verification image.
- User content: posts, comments, chat messages, reports.
- Profile data: profile image and profile fields.
- Device/app data: FCM token, notification settings, app activity needed for service operation.
- Image access: photo library/media access for uploads.
- Retention period.
- Account deletion and data deletion process.
- Data processors/service providers.
- Contact email.

## 11. Account Deletion

Because TeenPle allows users to create accounts, Google Play requires account deletion support.

Required:

- In-app path to delete the account or request deletion.
- Web URL where users can request account and data deletion even after uninstalling.
- Data safety deletion form completed in Play Console.

The web deletion page must:

- Load without error.
- Clearly reference TeenPle or the developer name.
- Make the deletion request path easy to find.
- Explain any retained data and retention reason.

## 12. UGC Policy Readiness

TeenPle includes user-generated content, so verify:

- Users accept terms before posting/uploading UGC.
- Terms define prohibited content and behavior.
- In-app reporting exists for posts.
- In-app reporting exists for comments.
- Blocking users is available for relevant user interactions.
- Admin/moderation tooling can act on reports.
- Safeguards exist against harassment, bullying, sexual content, illegal content, and other objectionable UGC.

Prepare review notes that explain:

- TeenPle is a school/community app with account-based access.
- Users can report posts and comments.
- Users can block other users.
- Admins review reports and can moderate content/users.

## 13. App Access For Review

Do not make reviewers complete a blocked verification flow.

Prepare:

- A regular approved test account.
- If needed, an admin test account.
- Passwords that will remain valid during review.
- Any school/user state required to see the main feed.

In Play Console App access notes, include:

- Login ID/email.
- Password.
- Steps to reach main features.
- Any feature limitations.
- Contact email for review blockers.

Example:

```text
Reviewer account:
ID: reviewer@example.com
Password: ********

This account is already school-verified. After login, reviewers can access the school feed, post detail, comments, report/block flows, profile, settings, and account deletion path.
```

## 14. Internal Testing

Upload the AAB to Internal testing first.

Steps:

- Test and release > Testing > Internal testing.
- Create new release.
- Upload `app-release.aab`.
- Add release notes.
- Add tester emails.
- Publish internal test.
- Install from the tester link on a real Android device.

Check Play Console pre-launch report for:

- Crashes.
- ANRs.
- Security warnings.
- Permission warnings.
- Login/access failures.
- Target API warnings.

## 15. Closed Testing Requirement

If the developer account is a personal account created after 2023-11-13, Google requires:

- Closed test before production.
- At least 12 testers.
- Testers opted in continuously for at least 14 days.
- Production access application after the requirement is met.

When applying for production access, be ready to answer:

- How testers were recruited.
- How testers used the app.
- What feedback was collected.
- What changes were made based on feedback.
- Why the app is ready for production.

## 16. Production Release

After internal/closed testing is clean:

- Go to Test and release > Production.
- Create new release.
- Select the reviewed AAB.
- Add release notes.
- Choose countries/regions.
- Review all warnings.
- Submit for review.

Consider enabling Managed publishing so approval does not immediately publish the app. This gives you control over the final release timing.

## 17. Final Pre-Submission Checklist

- `flutter analyze` passes.
- Release build uses release signing, not debug signing.
- `android/key.properties` exists locally.
- AAB builds successfully.
- `versionCode` is new.
- API server is live.
- Review account works.
- Ads are not visible.
- No Google test ad IDs remain in Android/iOS metadata.
- No `google_mobile_ads` dependency remains for the no-ads review build.
- Cleartext traffic is disabled in the main Android manifest.
- Privacy policy URL works.
- Account deletion web URL works.
- In-app account deletion path exists.
- UGC report/block/moderation flows work.
- Store screenshots match the submitted build.
- Data Safety answers match actual collection and sharing.
- App access notes are complete.

## 18. Official References

- Create and set up your app: https://support.google.com/googleplay/android-developer/answer/9859152
- Prepare your app for review: https://support.google.com/googleplay/android-developer/answer/9859455
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- UGC policy: https://support.google.com/googleplay/android-developer/answer/9876937
- Target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Personal account testing requirements: https://support.google.com/googleplay/android-developer/answer/14151465
