from fpdf import FPDF
from fpdf.enums import XPos, YPos
import os
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

FONT_PATH = "C:/Windows/Fonts/malgun.ttf"
FONT_BOLD_PATH = "C:/Windows/Fonts/malgunbd.ttf"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "docs", "legal")
os.makedirs(OUTPUT_DIR, exist_ok=True)

PRIMARY = (90, 142, 168)
DARK    = (17, 17, 17)
GRAY    = (100, 110, 120)
LIGHT   = (240, 244, 248)
WHITE   = (255, 255, 255)


class LegalPDF(FPDF):
    def __init__(self, title: str):
        super().__init__()
        self.doc_title = title
        self.add_font("Malgun", style="",  fname=FONT_PATH)
        self.add_font("Malgun", style="B", fname=FONT_BOLD_PATH)
        self.set_auto_page_break(auto=True, margin=20)

    # ── 헤더 ──────────────────────────────────────────
    def header(self):
        self.set_fill_color(*PRIMARY)
        self.rect(0, 0, 210, 18, style="F")
        self.set_font("Malgun", "B", 10)
        self.set_text_color(*WHITE)
        self.set_xy(10, 4)
        self.cell(0, 10, f"Teenple  |  {self.doc_title}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*DARK)
        self.ln(6)

    # ── 푸터 ──────────────────────────────────────────
    def footer(self):
        self.set_y(-14)
        self.set_font("Malgun", "", 8)
        self.set_text_color(*GRAY)
        self.cell(0, 8, f"{self.page_no()} / {{nb}}", align="C")

    # ── 표지 블록 ─────────────────────────────────────
    def cover_block(self, subtitle: str, effective_date: str):
        self.set_fill_color(*LIGHT)
        self.rect(10, self.get_y(), 190, 44, style="F")
        self.set_font("Malgun", "B", 20)
        self.set_text_color(*PRIMARY)
        self.set_xy(10, self.get_y() + 6)
        self.cell(190, 12, self.doc_title, align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font("Malgun", "", 11)
        self.set_text_color(*GRAY)
        self.cell(190, 8, subtitle, align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font("Malgun", "", 9)
        self.cell(190, 8, f"시행일: {effective_date}", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(10)

    # ── 챕터 제목 ────────────────────────────────────
    def chapter(self, text: str):
        self.set_fill_color(*PRIMARY)
        self.set_font("Malgun", "B", 11)
        self.set_text_color(*WHITE)
        self.set_x(10)
        self.cell(190, 9, f"  {text}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*DARK)
        self.ln(2)

    # ── 소제목 ───────────────────────────────────────
    def section(self, text: str):
        self.set_font("Malgun", "B", 10)
        self.set_text_color(*PRIMARY)
        self.set_x(10)
        self.cell(0, 8, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*DARK)

    # ── 본문 ─────────────────────────────────────────
    def body(self, text: str):
        self.set_font("Malgun", "", 9.5)
        self.set_x(10)
        self.multi_cell(190, 6, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    # ── 항목 (bullet) ────────────────────────────────
    def item(self, text: str, indent: int = 14):
        self.set_font("Malgun", "", 9.5)
        self.set_x(indent)
        self.multi_cell(190 - (indent - 10), 6, f"• {text}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    # ── 표 ───────────────────────────────────────────
    def table_row(self, col1: str, col2: str, header: bool = False):
        fill = PRIMARY if header else WHITE
        text = WHITE if header else DARK
        self.set_fill_color(*fill)
        self.set_text_color(*text)
        style = "B" if header else ""
        self.set_font("Malgun", style, 9)
        self.set_x(10)
        self.cell(55, 7, col1, border=1, fill=True)
        self.cell(135, 7, col2, border=1, fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*DARK)

    # ── 강조 박스 ────────────────────────────────────
    def notice_box(self, text: str):
        self.set_fill_color(255, 243, 224)
        self.set_draw_color(255, 160, 0)
        y = self.get_y()
        self.set_x(10)
        self.set_font("Malgun", "", 9)
        self.set_text_color(100, 60, 0)
        self.multi_cell(190, 6, text, border=1, fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*DARK)
        self.set_draw_color(0, 0, 0)
        self.ln(2)

    def spacer(self, h: int = 4):
        self.ln(h)


# ══════════════════════════════════════════════════════════════════
# 이용약관
# ══════════════════════════════════════════════════════════════════
def build_terms():
    pdf = LegalPDF("이용약관")
    pdf.alias_nb_pages()
    pdf.add_page()

    pdf.cover_block("Teenple 서비스 이용약관", "2026년 5월 1일")

    pdf.notice_box(
        "[주의]  본 서비스는 학교 인증을 완료한 재학생만 이용할 수 있습니다.\n"
        "        만 14세 미만 이용자는 법정대리인의 동의가 필요합니다."
    )

    # ── 제1조 ──────────────────────────────────────
    pdf.chapter("제1조 (목적)")
    pdf.body(
        "본 약관은 Teenple(이하 '회사')이 제공하는 학교 인증 기반 익명 커뮤니티 서비스 "
        "'Teenple'(이하 '서비스') 이용에 관한 제반 사항을 규정함을 목적으로 합니다."
    )

    # ── 제2조 ──────────────────────────────────────
    pdf.chapter("제2조 (용어의 정의)")
    pdf.item("'서비스': 회사가 제공하는 학교 인증 기반 커뮤니티 앱 및 관련 서비스 일체")
    pdf.item("'이용자': 본 약관에 동의하고 서비스를 이용하는 회원")
    pdf.item("'익명 게시': 다른 이용자에게 작성자 정보가 표시되지 않는 게시 방식 (서버에는 기록됨)")
    pdf.item("'학교 인증': 재학 중인 학교의 학생 신분을 학생증 등으로 확인하는 절차")
    pdf.spacer()

    # ── 제3조 ──────────────────────────────────────
    pdf.chapter("제3조 (약관의 효력 및 변경)")
    pdf.body(
        "① 본 약관은 서비스 화면에 게시하거나 이용자에게 공지함으로써 효력이 발생합니다.\n"
        "② 회사는 관련 법령을 위반하지 않는 범위에서 약관을 변경할 수 있으며, "
        "변경 시 적용일 7일 전에 공지합니다.\n"
        "③ 이용자가 변경된 약관에 동의하지 않을 경우 서비스 이용을 중단하고 탈퇴할 수 있습니다."
    )

    # ── 제4조 ──────────────────────────────────────
    pdf.chapter("제4조 (이용 자격)")
    pdf.body("① 서비스는 다음 요건을 모두 충족하는 자만 이용할 수 있습니다.")
    pdf.item("회사가 지정한 학교에 재학 중인 학생으로서 학교 인증을 완료한 자", indent=18)
    pdf.item("본 약관에 동의한 자", indent=18)
    pdf.item("만 14세 미만의 경우, 법정대리인의 동의를 받은 자", indent=18)
    pdf.body(
        "② 회사는 이용자가 허위 정보로 가입하거나 이용 자격을 상실한 경우 "
        "사전 통보 없이 이용을 제한할 수 있습니다.\n"
        "③ 졸업, 전학 등으로 재학생 신분이 변경된 경우 서비스 이용이 제한될 수 있습니다."
    )

    # ── 제5조 ──────────────────────────────────────
    pdf.chapter("제5조 (계정 관리)")
    pdf.body(
        "① 이용자는 계정 정보(이메일, 비밀번호 등)를 안전하게 관리할 책임이 있습니다.\n"
        "② 계정 도용이나 무단 사용을 인지한 경우 즉시 회사에 신고해야 합니다.\n"
        "③ 타인의 계정을 사용하거나 계정을 양도·대여하는 행위는 금지됩니다.\n"
        "④ 장기간(1년 이상) 미사용 계정은 사전 공지 후 삭제될 수 있습니다."
    )

    # ── 제6조 ──────────────────────────────────────
    pdf.chapter("제6조 (익명 게시 정책)")
    pdf.notice_box(
        "[중요]  익명으로 게시하더라도 서버에는 작성자 정보가 기록됩니다.\n"
        "        수사기관의 적법한 요청이 있을 경우 해당 정보가 제공될 수 있습니다.\n"
        "        익명이라도 모든 게시물에 대한 법적 책임은 작성자 본인에게 있습니다."
    )
    pdf.body(
        "① 서비스는 익명 게시와 닉네임 게시를 모두 지원합니다.\n"
        "② 익명 게시 시 다른 이용자에게는 작성자 정보가 공개되지 않으나, "
        "회사 서버에는 작성자 정보가 기록됩니다.\n"
        "③ 법원의 명령, 수사기관의 적법한 요청 등 법령에 따른 경우 작성자 정보가 제공될 수 있습니다."
    )

    # ── 제7조 ──────────────────────────────────────
    pdf.chapter("제7조 (금지 행위)")
    pdf.body("이용자는 다음 행위를 해서는 안 됩니다.")

    pdf.section("  가. 청소년 보호 관련")
    pdf.item("학교폭력, 사이버 따돌림, 집단 괴롭힘을 조장하거나 가담하는 행위")
    pdf.item("다른 이용자의 실명, 사진, 연락처, 위치 등 개인정보를 무단으로 공개하는 행위")
    pdf.item("성적 콘텐츠(수위 무관)를 게시하거나 유통하는 행위")
    pdf.item("자해·자살을 조장하거나 미화하는 콘텐츠를 게시하는 행위")
    pdf.item("음주, 흡연, 도박 등 청소년 유해 행위를 조장하는 행위")
    pdf.spacer(2)

    pdf.section("  나. 서비스 운영 관련")
    pdf.item("타인을 사칭하거나 허위 학교 인증 정보를 사용하는 행위")
    pdf.item("서비스의 정상적인 운영을 방해하는 행위 (DoS 공격, 스팸 등)")
    pdf.item("영리 목적의 광고, 홍보, 판매 행위")
    pdf.item("악성코드 배포, 해킹, 불법 접근 시도")
    pdf.item("타인의 지식재산권, 명예, 프라이버시를 침해하는 행위")
    pdf.item("관련 법령 및 공공질서·미풍양속에 반하는 행위")
    pdf.spacer()

    # ── 제8조 ──────────────────────────────────────
    pdf.chapter("제8조 (콘텐츠 정책)")
    pdf.body(
        "① 이용자가 작성한 게시물의 저작권은 해당 이용자에게 귀속됩니다.\n"
        "② 이용자는 게시물을 서비스에 게시함으로써 회사가 서비스 운영·개선 목적으로 "
        "해당 콘텐츠를 사용할 수 있는 비독점적 라이선스를 부여합니다.\n"
        "③ 회사는 다음에 해당하는 콘텐츠를 사전 통보 없이 삭제할 수 있습니다."
    )
    pdf.item("제7조의 금지 행위에 해당하는 콘텐츠")
    pdf.item("타인의 신고를 받아 검토 결과 부적절하다고 판단된 콘텐츠")
    pdf.item("법령 또는 본 약관을 위반하는 콘텐츠")

    # ── 제9조 ──────────────────────────────────────
    pdf.chapter("제9조 (신고 및 제재)")
    pdf.body(
        "① 이용자는 다른 이용자의 약관 위반 행위를 앱 내 신고 기능을 통해 신고할 수 있습니다.\n"
        "② 회사는 신고 접수 후 7일 이내에 검토 결과를 처리합니다.\n"
        "③ 위반 정도에 따라 경고, 게시물 삭제, 이용 정지(일시/영구)의 제재가 부과됩니다."
    )
    pdf.table_row("위반 유형", "제재 수준", header=True)
    pdf.table_row("경미한 위반 (1회)", "경고 및 게시물 삭제")
    pdf.table_row("반복 위반 (2~3회)", "7일~30일 이용 정지")
    pdf.table_row("중대한 위반", "즉시 영구 정지")
    pdf.table_row("성적 콘텐츠·학교폭력 조장", "즉시 영구 정지 및 수사기관 신고")
    pdf.spacer()
    pdf.body("④ 제재에 불복하는 경우 rkddk7165@naver.com으로 이의를 신청할 수 있습니다.")

    # ── 제10조 ──────────────────────────────────────
    pdf.chapter("제10조 (서비스 변경 및 중단)")
    pdf.body(
        "① 회사는 서비스의 내용, 기능, 운영 정책 등을 변경할 수 있으며, "
        "중요한 변경 사항은 사전에 공지합니다.\n"
        "② 천재지변, 국가비상사태, 시스템 장애 등 불가항력적 사유로 "
        "서비스가 중단될 수 있습니다.\n"
        "③ 회사는 서비스를 종료하고자 하는 경우 30일 전에 공지합니다."
    )

    # ── 제11조 ──────────────────────────────────────
    pdf.chapter("제11조 (면책 조항)")
    pdf.body(
        "① 회사는 이용자 간의 분쟁, 이용자가 게시한 콘텐츠로 인해 발생하는 "
        "제3자와의 분쟁에 대해 책임을 지지 않습니다.\n"
        "② 회사는 이용자의 귀책사유로 인한 서비스 이용 장애에 대해 책임을 지지 않습니다.\n"
        "③ 회사는 무료로 제공하는 서비스와 관련하여 법령이 허용하는 최대 한도 내에서 "
        "손해배상 책임을 면합니다."
    )

    # ── 제12조 ──────────────────────────────────────
    pdf.chapter("제12조 (준거법 및 관할)")
    pdf.body(
        "① 본 약관은 대한민국 법령에 따라 해석됩니다.\n"
        "② 서비스 이용과 관련한 분쟁은 서울중앙지방법원을 제1심 관할 법원으로 합니다."
    )

    # ── 운영자 정보 ─────────────────────────────────
    pdf.chapter("운영자 정보")
    pdf.table_row("항목", "내용", header=True)
    pdf.table_row("서비스명", "Teenple")
    pdf.table_row("운영 주체", "Teenple")
    pdf.table_row("대표 연락처", "010-7165-1075")
    pdf.table_row("이메일", "rkddk7165@naver.com")
    pdf.table_row("시행일", "2026년 5월 1일")

    out = os.path.join(OUTPUT_DIR, "Teenple_이용약관.pdf")
    pdf.output(out)
    print(f"[완료] 이용약관 생성: {out}")


# ══════════════════════════════════════════════════════════════════
# 개인정보처리방침
# ══════════════════════════════════════════════════════════════════
def build_privacy():
    pdf = LegalPDF("개인정보처리방침")
    pdf.alias_nb_pages()
    pdf.add_page()

    pdf.cover_block(
        "Teenple 개인정보처리방침 (개인정보보호법 제30조)",
        "2026년 5월 1일"
    )

    pdf.notice_box(
        "Teenple은 이용자의 개인정보를 중요하게 여기며, "
        "개인정보보호법 등 관련 법령을 철저히 준수합니다.\n"
        "본 방침은 서비스 이용 과정에서 수집·이용·보관·파기되는 "
        "개인정보에 관한 사항을 안내합니다."
    )

    # ── 제1조 ──────────────────────────────────────
    pdf.chapter("제1조 (수집하는 개인정보 항목)")

    pdf.section("  가. 회원가입 시 수집 항목")
    pdf.table_row("구분", "항목", header=True)
    pdf.table_row("필수", "이메일, 닉네임, 비밀번호(암호화 저장), 성별, 학년")
    pdf.table_row("필수", "재학 학교명, 반, 전화번호")
    pdf.table_row("학교 인증용", "학생증 이미지 (인증 완료 후 즉시 파기)")
    pdf.table_row("선택", "프로필 이미지 URL")
    pdf.spacer(2)

    pdf.section("  나. 서비스 이용 중 자동 수집 항목")
    pdf.item("기기 정보: OS 종류(Android/iOS)")
    pdf.item("푸시 알림 토큰 (FCM Token) — 알림 전송 목적")
    pdf.item("IP 주소, 접속 일시, 서비스 이용 기록")
    pdf.item("게시글, 댓글, 채팅 내용 및 신고·제재 이력")
    pdf.spacer()

    # ── 제2조 ──────────────────────────────────────
    pdf.chapter("제2조 (개인정보의 수집·이용 목적)")
    pdf.table_row("목적", "수집 항목", header=True)
    pdf.table_row("학교 인증 및 본인 확인", "이메일, 전화번호, 학생증 이미지, 학교명")
    pdf.table_row("서비스 제공 (게시, 댓글, 채팅)", "닉네임, 학교명, 학년, 성별")
    pdf.table_row("푸시 알림 발송", "FCM 토큰, OS 정보")
    pdf.table_row("부정 이용 방지 및 제재", "IP 주소, 이용 기록, 신고 이력")
    pdf.table_row("법적 의무 이행", "이용 기록, 계정 정보")
    pdf.spacer()

    # ── 제3조 ──────────────────────────────────────
    pdf.chapter("제3조 (개인정보의 보유 및 이용 기간)")
    pdf.body(
        "① 개인정보는 수집·이용 목적이 달성되면 지체 없이 파기합니다.\n"
        "② 단, 관련 법령에 따라 일정 기간 보존이 필요한 경우 별도 보관합니다."
    )
    pdf.table_row("보존 항목", "보존 기간 / 근거", header=True)
    pdf.table_row("학생증 이미지", "학교 인증 완료 즉시 파기")
    pdf.table_row("회원 탈퇴 후 계정 정보", "즉시 파기 (단, 제재 이력 1년 보존)")
    pdf.table_row("서비스 이용 기록", "3개월 (통신비밀보호법)")
    pdf.table_row("전자금융거래 기록 (향후 유료 기능 시)", "5년 (전자금융거래법)")
    pdf.table_row("소비자 불만·분쟁 처리 기록", "3년 (전자상거래법)")
    pdf.spacer()

    # ── 제4조 ──────────────────────────────────────
    pdf.chapter("제4조 (개인정보의 제3자 제공)")
    pdf.body(
        "① Teenple은 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다.\n"
        "② 다음의 경우 예외적으로 제공될 수 있습니다."
    )
    pdf.item("이용자가 사전에 동의한 경우")
    pdf.item("법원의 명령, 수사기관의 적법한 절차에 따른 요청이 있는 경우")
    pdf.item("이용자 또는 제3자의 생명·신체·재산 보호를 위해 긴급히 필요한 경우")
    pdf.spacer()

    # ── 제5조 ──────────────────────────────────────
    pdf.chapter("제5조 (개인정보 처리 위탁)")
    pdf.body("원활한 서비스 제공을 위해 아래와 같이 개인정보 처리를 위탁합니다.")
    pdf.table_row("수탁업체", "위탁 업무", header=True)
    pdf.table_row("Google Firebase (Google LLC)", "클라우드 서버 인프라, FCM 푸시 알림")
    pdf.table_row("(추후 결제 연동 시 추가 예정)", "—")
    pdf.body(
        "\n각 수탁업체는 개인정보를 위탁받은 목적 외에 사용하지 않으며, "
        "관련 법령에 따라 안전하게 관리합니다."
    )

    # ── 제6조 ──────────────────────────────────────
    pdf.chapter("제6조 (만 14세 미만 이용자 처리 방침)")
    pdf.notice_box(
        "[주의]  만 14세 미만 아동의 개인정보 수집 시 법정대리인(부모 등)의 동의가 필요합니다.\n"
        "        (개인정보보호법 제22조 제6항)"
    )
    pdf.body(
        "① 만 14세 미만 이용자는 가입 시 법정대리인의 동의를 받아야 합니다.\n"
        "② 법정대리인은 해당 아동의 개인정보 열람, 정정, 삭제, 처리정지를 요청할 수 있습니다.\n"
        "③ 법정대리인 동의 없이 수집된 것으로 확인된 경우 즉시 해당 정보를 파기합니다.\n"
        "④ 법정대리인 권리 행사: rkddk7165@naver.com"
    )

    # ── 제7조 ──────────────────────────────────────
    pdf.chapter("제7조 (정보주체의 권리·의무 및 행사 방법)")
    pdf.body(
        "이용자(정보주체)는 언제든지 다음 권리를 행사할 수 있습니다."
    )
    pdf.item("개인정보 열람 요청")
    pdf.item("오류가 있는 개인정보 정정 요청")
    pdf.item("개인정보 삭제 요청 (법령에 따른 보존 기간이 남은 정보 제외)")
    pdf.item("개인정보 처리정지 요청")
    pdf.body(
        "\n권리 행사는 앱 내 [내 정보] 메뉴 또는 이메일(rkddk7165@naver.com)로 요청하실 수 있으며, "
        "요청 접수 후 10일 이내에 처리합니다."
    )

    # ── 제8조 ──────────────────────────────────────
    pdf.chapter("제8조 (개인정보의 파기 절차 및 방법)")
    pdf.body(
        "① 보유 기간이 경과하거나 처리 목적이 달성된 개인정보는 지체 없이 파기합니다.\n"
        "② 파기 방법"
    )
    pdf.item("전자적 파일: 복구 불가능한 방법(덮어쓰기 또는 안전 삭제)으로 영구 삭제")
    pdf.item("학생증 이미지: 인증 완료 즉시 스토리지에서 삭제, 서버 로그에서도 제거")

    # ── 제9조 ──────────────────────────────────────
    pdf.chapter("제9조 (개인정보의 안전성 확보 조치)")
    pdf.table_row("조치 유형", "세부 내용", header=True)
    pdf.table_row("암호화", "HTTPS 전송, BCrypt 비밀번호 암호화")
    pdf.table_row("접근 통제", "JWT 토큰 인증, 역할 기반 접근 제어")
    pdf.table_row("토큰 관리", "Access Token 단기 만료, Refresh Token 갱신 방식")
    pdf.table_row("모니터링", "비정상 접근 패턴 탐지 및 자동 차단")
    pdf.table_row("학생증 이미지", "인증 완료 후 즉시 파기, 임시 저장 최소화")

    # ── 제10조 ──────────────────────────────────────
    pdf.chapter("제10조 (개인정보 보호책임자)")
    pdf.table_row("항목", "내용", header=True)
    pdf.table_row("보호책임자", "Teenple 운영팀")
    pdf.table_row("연락처", "010-7165-1075")
    pdf.table_row("이메일", "rkddk7165@naver.com")
    pdf.body(
        "\n개인정보 관련 문의, 불만, 피해구제 등은 위 연락처로 문의하시면 "
        "신속하게 처리하겠습니다."
    )

    pdf.spacer()
    pdf.body(
        "개인정보 침해에 관한 신고·상담은 아래 기관에도 문의하실 수 있습니다.\n"
        "• 개인정보보호위원회: www.pipc.go.kr / 국번없이 182\n"
        "• 한국인터넷진흥원 개인정보침해신고센터: privacy.kisa.or.kr / 국번없이 118\n"
        "• 대검찰청 사이버수사과: www.spo.go.kr / 국번없이 1301\n"
        "• 경찰청 사이버수사국: cyberbureau.police.go.kr / 국번없이 182"
    )

    # ── 제11조 ──────────────────────────────────────
    pdf.chapter("제11조 (개인정보처리방침 변경)")
    pdf.body(
        "본 방침은 법령 또는 서비스 정책 변경에 따라 수정될 수 있습니다.\n"
        "변경 시 앱 공지 또는 이메일을 통해 7일 전에 고지합니다.\n\n"
        "공고일: 2026년 4월 24일\n"
        "시행일: 2026년 5월 1일"
    )

    out = os.path.join(OUTPUT_DIR, "Teenple_개인정보처리방침.pdf")
    pdf.output(out)
    print(f"[완료] 개인정보처리방침 생성: {out}")


if __name__ == "__main__":
    build_terms()
    build_privacy()
    print("\n[완료] docs/legal/ 폴더에 저장되었습니다.")
