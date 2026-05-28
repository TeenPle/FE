# 🌿 TeenPle(Teenage Place) — Frontend

고등학생이 자신의 학교를 인증하고 참여할 수 있는  
**학교 전용 익명 커뮤니티 TeenPle**(Teenage Place)의 **Flutter 모바일 앱 레포지토리**입니다.

본 저장소는 회원가입, 학교 인증, 게시판, 댓글, 채팅, 알림, 마이페이지 등 TeenPle의 사용자 앱 화면과 클라이언트 기능을 담당합니다.

<div align="center">
  <img width="380" alt="TeenPle Poster" src="https://github.com/user-attachments/files/28346924/default.bmp" />
</div>

---

## 📱 App Preview

<div align="center">
  <img width="260" alt="TeenPle Landing" src="assets/images/teenple_landing.png" />
</div>

---

## 🚀 Tech Stack

### Frontend

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

### State / Routing

![Riverpod](https://img.shields.io/badge/Riverpod-40B5AD?style=for-the-badge&logo=flutter&logoColor=white)
![go_router](https://img.shields.io/badge/go_router-02569B?style=for-the-badge&logo=flutter&logoColor=white)

### Network / Storage

![Dio](https://img.shields.io/badge/Dio-000000?style=for-the-badge&logo=dart&logoColor=white)
![Secure Storage](https://img.shields.io/badge/Secure%20Storage-4A5568?style=for-the-badge&logo=googlecloud&logoColor=white)
![SharedPreferences](https://img.shields.io/badge/SharedPreferences-6B7280?style=for-the-badge&logo=flutter&logoColor=white)

### Realtime / Notification

![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=for-the-badge&logo=socket.io&logoColor=white)
![Firebase Messaging](https://img.shields.io/badge/Firebase%20Messaging-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

### Platform

![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

---

## ✨ 주요 기능

- 학교 인증 기반 회원가입 및 로그인
- 학교별 게시판, 인기글, 검색, 북마크
- 게시글 작성, 댓글, 대댓글, 공감, 신고, 차단
- 실시간 1:1 채팅 및 채팅방 알림 설정
- Firebase Cloud Messaging 기반 푸시 알림
- 급식, 시간표, D-Day 등 학교생활 편의 기능
- 내 게시글, 내 댓글, 좋아요, 북마크, 프로필 관리
- 관리자 신고/인증/제재 관리 화면

---

## 🔧 실행 방법

```bash
flutter pub get
flutter run
```

Android 릴리즈 빌드:

```bash
flutter build apk --release
```

환경별 API 주소와 Firebase 설정 파일은 로컬에서만 관리합니다.

- `android/app/google-services.json`
- `lib/firebase_options.dart`

위 파일은 실제 서비스 키가 포함될 수 있으므로 Git에 커밋하지 않습니다.

---

## 📁 프로젝트 구조

```text
lib
├─ app                         # 앱 라우팅, 테마, 전역 앱 설정
├─ core                        # 공통 네트워크, 인증, 저장소, 위젯, 테마
│  ├─ auth                     # 인증 세션 상태
│  ├─ network                  # Dio, API 클라이언트, 예외 처리
│  ├─ storage                  # 토큰 및 로컬 저장소
│  ├─ theme                    # 컬러, 텍스트 스타일, 다크모드
│  └─ widgets                  # 공통 UI 컴포넌트
│
├─ features                    # 기능 단위 화면/상태/API 모듈
│  ├─ admin                    # 관리자 화면
│  ├─ auth                     # 로그인, 회원가입, 계정 복구
│  ├─ chat                     # 채팅방, 메시지, WebSocket
│  ├─ notification             # 알림 목록, FCM 연동
│  ├─ post                     # 게시글 상세, 댓글, 공감, 신고
│  ├─ profile                  # 마이페이지, 프로필, 설정
│  ├─ school                   # 학교 메인, 게시판, 인기글
│  └─ search                   # 게시글 검색
│
└─ main.dart                   # 앱 진입점
```

---

## 📌 협업 규칙

### 🌿 브랜치 전략

우리 팀은 다음과 같은 브랜치 전략을 사용합니다.

- `main` : 실제 배포용 브랜치
- `develop` : 개발 통합 브랜치
- `demo` : 시연/테스트 서버 배포용 브랜치

#### 작업 브랜치 전략

이슈 단위로 브랜치를 생성하고, 작업 완료 후 `develop` 브랜치로 병합합니다.

- 기능 개발 : `feat/{이슈번호}-{간단설명}`
- 버그 수정 : `fix/{이슈번호}-{간단설명}`
- 문서/설정 : `chore/{이슈번호}-{간단설명}` 또는 `docs/{이슈번호}-{간단설명}`

예시:

- `feat/11-chat`
- `fix/55-logging-and-bugfixes`

#### 기본 워크플로우

1. 이슈 생성 (`#11 채팅 기능 구현` 등)
2. `develop` 기준으로 작업 브랜치 생성  
   `git checkout -b feat/11-chat develop`
3. 커밋 메시지에 이슈 번호 연동  
   `Feat: 채팅 화면 구현`
4. `develop` 대상으로 PR 생성
   - PR 본문에 `Resolves #11` 작성
5. 코드 리뷰 후 `develop`에 머지
6. 필요 시 `develop` → `demo`, 안정화 후 `develop` → `main` 배포

---

## 📝 커밋 컨벤션

### 1️⃣ Commit Type

| Type         | 설명                                |
| ------------ | ----------------------------------- |
| **Feat**     | 새로운 기능 추가                    |
| **Fix**      | 버그 수정                           |
| **Docs**     | 문서 수정                           |
| **Style**    | 코드 포맷팅(동작 영향 없음)         |
| **Refactor** | 코드 리팩토링                       |
| **Test**     | 테스트 코드 추가/수정               |
| **Chore**    | 기타 변경사항(빌드, 패키지 정리 등) |
| **Design**   | UI/CSS 등 디자인 관련 수정          |
| **Comment**  | 주석 추가/변경                      |
| **Init**     | 프로젝트 초기 설정                  |
| **Rename**   | 파일/폴더명 변경                    |
| **Remove**   | 파일 삭제                           |

---

### 2️⃣ Subject Rule

- 제목은 **50자 이하**
- **마침표/특수기호 X**
- 영문 시 **동사 원형**, 첫 글자 대문자
- **개조식 표현** 사용

---

### 3️⃣ Body Rule

- 한 줄 **72자 이하**
- "무엇을, 왜 변경했는지" 중심
- 선택이지만 가급적 작성 권장

---

### 4️⃣ Footer Rule

- 형식: `유형: #이슈번호`
- 여러 개일 경우 쉼표로 구분
- 사용 가능한 유형:

| 유형           | 설명                 |
| -------------- | -------------------- |
| **Fixes**      | 이슈 수정 중(미해결) |
| **Resolves**   | 이슈 해결            |
| **Ref**        | 참고할 이슈          |
| **Related to** | 관련된 이슈(미해결)  |

#### 예시

```text
Feat: Add chat room page

채팅방 목록 및 메시지 화면 구현
WebSocket 연결 상태 UI 반영

Resolves: #11
```

---

## 👥 Team

<table>
  <tr>
    <td align="center" width="200">
      <a href="https://github.com/hongwangki">
        <img src="./assets/team/develop.png" width="150">
        <br><b>홍왕기</b>
      </a>
    </td>
    <td align="center" width="200">
      <a href="https://github.com/rkddk7165">
        <img src="./assets/team/develop2.png" width="150">
        <br><b>강현민</b>
      </a>
    </td>
  </tr>
</table>
