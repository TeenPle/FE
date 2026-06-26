# TeenPle 공식 웹 페이지 AWS 배포 가이드

이 문서는 Google Play/App Store 심사용 공식 웹 페이지를 `teenple.app` 도메인에서 제공하기 위한 AWS 설정 절차입니다.

대상 URL:

- `https://teenple.app/`
- `https://teenple.app/terms`
- `https://teenple.app/privacy`
- `https://teenple.app/privacy-consent`
- `https://teenple.app/support`
- `https://teenple.app/account-deletion`

## 전제

- `teenple.app` 도메인은 이미 Route53 Hosted Zone으로 관리한다고 가정한다.
- `api.teenple.app`은 기존 백엔드 API 도메인이므로 건드리지 않는다.
- 정적 페이지 파일은 FE repo의 `web/` 아래에 있다.
- 실제 배포 산출물은 `flutter build web`으로 생성되는 `build/web` 전체다.

## 전체 구조

권장 구조:

```text
Route53 teenple.app
  -> CloudFront
      -> S3 private bucket
```

S3 public static website hosting만으로도 정적 페이지를 띄울 수는 있지만, HTTPS, 루트 도메인 연결, 캐시, 보안, 향후 확장을 고려하면 CloudFront + S3 private bucket 구성이 적합하다.

## 1. 로컬에서 배포 산출물 만들기

FE repo에서 실행한다.

```powershell
cd C:\develop\FE
flutter build web
```

빌드 성공 후 아래 파일이 있는지 확인한다.

```text
C:\develop\FE\build\web\terms\index.html
C:\develop\FE\build\web\privacy\index.html
C:\develop\FE\build\web\privacy-consent\index.html
C:\develop\FE\build\web\support\index.html
C:\develop\FE\build\web\account-deletion\index.html
```

`C:\develop\FE\build\web\index.html`은 Flutter Web 앱 실행 페이지가 아니라 공식 안내 페이지다. 루트 도메인 `https://teenple.app/`에서는 앱 로그인 화면이 아니라 문의, 약관, 개인정보 문서 링크가 보여야 한다.

S3에는 `build/web` 폴더 자체가 아니라 `build/web` 안의 파일과 폴더가 버킷 루트에 올라가야 한다.

올바른 S3 구조:

```text
index.html
flutter.js
main.dart.js
assets/
terms/index.html
privacy/index.html
privacy-consent/index.html
support/index.html
account-deletion/index.html
```

잘못된 구조:

```text
build/web/index.html
build/web/terms/index.html
```

## 2. S3 버킷 생성

AWS Console에서 S3로 이동한다.

1. `Create bucket` 클릭
2. 아래 값으로 생성

```text
Bucket name: teenple-web-prod
Region: ap-northeast-2, Asia Pacific (Seoul)
Object Ownership: ACLs disabled
Block all public access: ON
Bucket Versioning: Enable 권장
Default encryption: SSE-S3
```

주의:

- 버킷은 public으로 열지 않는다.
- CloudFront Origin Access Control, 즉 OAC를 통해서만 접근하게 만든다.
- S3의 `Static website hosting` 기능은 켜지 않는다. CloudFront + S3 REST origin으로 구성한다.

## 3. ACM 인증서 발급

CloudFront에 연결할 인증서는 반드시 `us-east-1`, 즉 N. Virginia 리전에서 만들어야 한다.

AWS Console 상단 리전을 아래로 변경한다.

```text
US East (N. Virginia) us-east-1
```

ACM으로 이동한 뒤:

1. `Request certificate`
2. `Request a public certificate`
3. 도메인 입력

```text
teenple.app
```

`www.teenple.app`도 사용할 예정이면 함께 추가한다.

```text
www.teenple.app
```

검증 방식:

```text
DNS validation
```

인증서 생성 후 `Create records in Route 53` 버튼이 보이면 클릭한다.

상태가 아래처럼 바뀔 때까지 기다린다.

```text
Pending validation -> Issued
```

`Issued`가 되기 전에는 CloudFront에 연결할 수 없다.

## 4. CloudFront Distribution 생성

AWS Console에서 CloudFront로 이동한 뒤 `Create distribution`을 클릭한다.

### Origin 설정

Origin domain은 S3 bucket의 REST endpoint를 선택한다.

```text
Origin domain: teenple-web-prod.s3.ap-northeast-2.amazonaws.com
```

주의:

- `s3-website` endpoint를 고르지 않는다.
- 일반 S3 REST endpoint를 사용한다.

Origin access:

```text
Origin access: Origin access control settings
Origin access control: Create new OAC
```

OAC 이름 예시:

```text
teenple-web-prod-oac
```

### Default cache behavior

```text
Viewer protocol policy: Redirect HTTP to HTTPS
Allowed HTTP methods: GET, HEAD, OPTIONS
Cache HTTP methods: GET, HEAD
Cache policy: CachingOptimized
Compress objects automatically: Yes
```

### Distribution settings

```text
Alternate domain name (CNAME): teenple.app
Custom SSL certificate: us-east-1에서 발급한 teenple.app 인증서
Default root object: index.html
Supported HTTP versions: HTTP/2 또는 HTTP/2 + HTTP/3
IPv6: Enabled 권장
```

생성 후 CloudFront가 S3 bucket policy를 업데이트하라는 안내를 보여준다. `Copy policy`로 복사한 뒤:

1. S3로 이동
2. `teenple-web-prod` 버킷 클릭
3. `Permissions`
4. `Bucket policy`
5. CloudFront가 안내한 policy 붙여넣기
6. 저장

## 5. Clean URL 처리를 위한 CloudFront Function 생성

브라우저에서는 아래 URL로 접근해야 한다.

```text
https://teenple.app/terms
https://teenple.app/privacy
https://teenple.app/privacy-consent
```

하지만 S3 실제 파일은 아래 위치에 있다.

```text
terms/index.html
privacy/index.html
privacy-consent/index.html
```

따라서 CloudFront에서 확장자가 없는 경로를 `/{path}/index.html`로 바꿔줘야 한다.

CloudFront Console에서:

1. `Functions`
2. `Create function`
3. 이름 입력

```text
teenple-clean-url-rewrite
```

코드:

```js
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith('/')) {
    request.uri = uri + 'index.html';
    return request;
  }

  if (!uri.includes('.')) {
    request.uri = uri + '/index.html';
    return request;
  }

  return request;
}
```

저장 후:

1. `Publish`
2. CloudFront Distribution으로 이동
3. `Behaviors`
4. Default behavior 선택
5. `Edit`
6. Function associations 설정

```text
Viewer request: CloudFront Functions
Function: teenple-clean-url-rewrite
```

이 설정이 없으면 `/terms/index.html`은 열리지만 `/terms`는 403 또는 404가 날 수 있다.

## 6. S3에 `build/web` 업로드

S3 Console에서 `teenple-web-prod` 버킷으로 이동한다.

1. `Upload`
2. `C:\develop\FE\build\web` 안의 모든 파일과 폴더 선택
3. 업로드

반드시 업로드 후 아래 경로가 S3 루트 기준으로 존재하는지 확인한다.

```text
terms/index.html
privacy/index.html
privacy-consent/index.html
support/index.html
account-deletion/index.html
```

## 7. Route53에서 `teenple.app` 연결

Route53으로 이동한다.

1. `Hosted zones`
2. `teenple.app` 선택
3. `Create record`

루트 도메인 A 레코드:

```text
Record name: 비워둠
Record type: A
Alias: ON
Route traffic to: Alias to CloudFront distribution
Distribution: 방금 만든 CloudFront distribution
```

IPv6를 켰다면 AAAA 레코드도 만든다.

```text
Record name: 비워둠
Record type: AAAA
Alias: ON
Route traffic to: Alias to CloudFront distribution
Distribution: 방금 만든 CloudFront distribution
```

주의:

- `api.teenple.app` 레코드는 건드리지 않는다.
- `teenple.app` 루트 도메인은 일반 CNAME이 아니라 Route53 Alias를 사용한다.

## 8. 배포 완료 대기

CloudFront Distribution 상태가 아래처럼 바뀔 때까지 기다린다.

```text
Deploying -> Deployed
```

몇 분 걸릴 수 있다.

## 9. 접속 테스트

PowerShell에서 확인한다.

```powershell
curl.exe -I https://teenple.app/terms
curl.exe -I https://teenple.app/privacy
curl.exe -I https://teenple.app/privacy-consent
curl.exe -I https://teenple.app/support
curl.exe -I https://teenple.app/account-deletion
```

기대값:

```text
HTTP/2 200
```

브라우저에서도 직접 확인한다.

```text
https://teenple.app/terms
https://teenple.app/privacy
https://teenple.app/privacy-consent
https://teenple.app/support
https://teenple.app/account-deletion
```

확인할 것:

- HTTPS 경고가 없어야 한다.
- 한글이 깨지지 않아야 한다.
- `https://teenple.app/`에서는 공식 안내 페이지가 보여야 한다.
- `/terms`처럼 `index.html` 없는 주소도 열려야 한다.
- `privacy-consent`가 개인정보처리방침이 아니라 개인정보 수집·이용 동의 문서여야 한다.
- `api.teenple.app` API는 기존처럼 동작해야 한다.

## 10. 수정 배포 절차

페이지 내용이나 빌드 산출물이 바뀌면 다시 빌드한다.

```powershell
cd C:\develop\FE
flutter build web
```

그 다음 `build/web` 안의 모든 파일을 S3에 다시 업로드한다.

업로드 후 CloudFront cache invalidation을 만든다.

CloudFront:

1. Distribution 선택
2. `Invalidations`
3. `Create invalidation`
4. Paths 입력

심사 직전에는 전체 무효화가 안전하다.

```text
/*
```

비용과 시간을 줄이고 싶으면 필요한 경로만 무효화한다.

```text
/terms*
/privacy*
/privacy-consent*
/support*
/account-deletion*
```

## 11. Google Play Console 입력 URL

```text
개인정보처리방침 URL:
https://teenple.app/privacy

계정 삭제 URL:
https://teenple.app/account-deletion

지원 문의 URL:
https://teenple.app/support

서비스 이용약관:
https://teenple.app/terms

개인정보 수집·이용 동의:
https://teenple.app/privacy-consent
```

## 12. 백엔드 보안 설정 체크

백엔드가 실제 HTML을 서빙하지 않더라도, 라우팅 실수로 아래 요청이 백엔드로 들어갈 수 있다.

```text
/terms
/privacy
/privacy-consent
/support
/account-deletion
```

백엔드 SecurityConfig에는 아래 경로가 `permitAll()`로 열려 있어야 한다.

```text
/
/terms
/terms/**
/privacy
/privacy/**
/privacy-consent
/privacy-consent/**
/support
/support/**
/account-deletion
/account-deletion/**
/favicon.ico
```

관련 파일:

```text
C:\develop\BE\backend\src\main\java\com\shu\backend\global\security\SecurityConfig.java
```

검증:

```powershell
cd C:\develop\BE\backend
.\gradlew.bat compileJava
```

기대값:

```text
BUILD SUCCESSFUL
```

## 13. 문제 상황별 확인

### `/terms`는 안 열리고 `/terms/index.html`만 열린다

CloudFront Function 연결이 빠졌거나 publish되지 않은 상태다.

확인:

- Function code가 publish되어 있는지
- Distribution default behavior의 Viewer request에 연결되어 있는지

### 403 AccessDenied가 나온다

가능성:

- S3 bucket policy에 CloudFront OAC 허용 정책이 없음
- CloudFront origin이 잘못된 S3 bucket을 보고 있음
- 파일이 S3에 업로드되지 않음

확인:

- S3에 `terms/index.html`, `privacy/index.html`, `privacy-consent/index.html` 존재 여부
- CloudFront OAC policy 적용 여부
- Distribution origin bucket 이름

### HTTPS 인증서를 선택할 수 없다

ACM 인증서는 `ap-northeast-2`가 아니라 `us-east-1`에서 만들어야 한다.

확인:

- AWS Console region이 `US East (N. Virginia) us-east-1`인지
- 인증서 상태가 `Issued`인지

### `api.teenple.app`이 깨졌다

Route53에서 `api.teenple.app` 레코드를 건드렸을 가능성이 있다.

확인:

- `teenple.app` 루트 A/AAAA alias만 CloudFront로 연결했는지
- `api.teenple.app` 기존 A/CNAME 레코드는 유지되는지

### 수정 내용이 반영되지 않는다

CloudFront 캐시가 남아 있을 수 있다.

해결:

```text
CloudFront invalidation: /*
```

## 14. 최종 체크리스트

- [ ] `flutter build web` 성공
- [ ] S3 버킷 생성 완료
- [ ] S3 public access block 유지
- [ ] ACM 인증서가 `us-east-1`에서 `Issued`
- [ ] CloudFront distribution 생성
- [ ] CloudFront OAC 생성
- [ ] S3 bucket policy에 CloudFront OAC 허용 정책 적용
- [ ] CloudFront Function 생성 및 publish
- [ ] Default behavior에 CloudFront Function 연결
- [ ] Route53 `teenple.app` A alias 생성
- [ ] 필요한 경우 Route53 `teenple.app` AAAA alias 생성
- [ ] `https://teenple.app/terms` 200 확인
- [ ] `https://teenple.app/privacy` 200 확인
- [ ] `https://teenple.app/privacy-consent` 200 확인
- [ ] `https://teenple.app/support` 200 확인
- [ ] `https://teenple.app/account-deletion` 200 확인
- [ ] `api.teenple.app` 기존 API 정상 확인
- [ ] Google Play Console에 공식 URL 입력
