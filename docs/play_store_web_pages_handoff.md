# Play Store 심사용 공식 웹 페이지 작업 정리

## 생성된 공식 웹 페이지

- `https://teenple.app/terms`
  - 위치: `web/terms/index.html`
  - 서비스 이용약관 원문
- `https://teenple.app/privacy`
  - 위치: `web/privacy/index.html`
  - 개인정보처리방침 원문
- `https://teenple.app/privacy-consent`
  - 위치: `web/privacy-consent/index.html`
  - 회원가입 필수 동의인 개인정보 수집·이용 동의 원문
- `https://teenple.app/support`
  - 위치: `web/support/index.html`
  - 일반 문의: `teenple.official@gmail.com`
- `https://teenple.app/account-deletion`
  - 위치: `web/account-deletion/index.html`
  - Google Play 데이터 보안의 계정 삭제 URL로 사용 가능

## 코드 반영 내용

- 회원가입 동의 원문 링크
  - 서비스 이용약관: `https://teenple.app/terms`
  - 개인정보 수집·이용 동의: `https://teenple.app/privacy-consent`
- 프로필/설정의 약관 및 개인정보처리방침 진입은 공식 웹 페이지로 연결한다.
- 프로필/설정의 문의하기는 `https://teenple.app/support`를 외부 브라우저로 연다.
- 사용자 문의 화면은 제거하고, 관리자 문의 관리 기능은 유지한다.

## 배포 전 필수 확인

1. `teenple.app` 정적 호스팅에서 아래 경로가 직접 열려야 한다.
   - `/terms`
   - `/privacy`
   - `/privacy-consent`
   - `/support`
   - `/account-deletion`
2. 호스팅이 SPA fallback을 쓰는 경우, 위 경로가 `/index.html`로 덮이지 않도록 정적 파일 우선 규칙이 필요하다.
3. HTTPS 인증서가 유효해야 한다.
4. Play Console 입력값
   - 개인정보처리방침 URL: `https://teenple.app/privacy`
   - 계정 삭제 URL: `https://teenple.app/account-deletion`
   - 개발자 지원 연락처: `teenple.official@gmail.com`
5. 약관 또는 개인정보 문서가 변경되면 `web/terms`, `web/privacy`, `web/privacy-consent`를 함께 최신화한다.

## 검수 기준

- 앱 안에서 사용자가 접근하는 약관/개인정보/문의는 모두 공식 도메인의 웹 페이지로 열린다.
- 회원가입의 개인정보 수집·이용 동의 원문은 개인정보처리방침과 별도 URL인 `/privacy-consent`로 열린다.
- 앱 내부 사용자 문의 화면은 남아 있지 않다.
- 관리자 문의 관리 기능은 제거하지 않는다.
