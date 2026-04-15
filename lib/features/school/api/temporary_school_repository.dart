import '../models/board_model.dart';
import '../models/board_post_page.dart';
import '../models/post_sort_type.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';
import 'school_repository.dart';

/// 목업 데이터 기반 학교 Repository
class TemporarySchoolRepository implements SchoolRepository {
  const TemporarySchoolRepository();

  /// 학교 상세와 기본 게시판 게시글을 반환
  @override
  Future<SchoolResponse> getSchoolDetail({
    required int schoolId,
    int page = 0,
    int size = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    const boards = [
      BoardModel(id: 1, title: '자유게시판', description: '자유롭게 대화하는 공간', active: true),
      BoardModel(id: 2, title: '질문게시판', description: '질문을 올리는 공간', active: true),
      BoardModel(id: 3, title: '정보게시판', description: '정보를 공유하는 공간', active: true),
      BoardModel(id: 4, title: '시사게시판', description: '시사 이슈를 다루는 공간', active: true),
    ];

    final firstPage = await getPostsByBoard(
      boardId: 1,
      sortType: PostSortType.latest,
      page: page,
      size: size,
    );

    return SchoolResponse(
      schoolId: schoolId,
      name: '틴플고등학교',
      description: '학교 설명',
      boards: boards,
      posts: firstPage.posts,
      hasNext: firstPage.hasNext,
    );
  }

  /// 게시판 게시글 목록을 정렬/페이지 기준으로 잘라서 반환
  @override
  Future<BoardPostPage> getPostsByBoard({
    required int boardId,
    required PostSortType sortType,
    int page = 0,
    int size = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 220));

    final source = List<PostSummary>.from(_postsByBoard[boardId] ?? const []);

    // 정렬 기준에 따라 목록 정렬
    if (sortType == PostSortType.latest) {
      source.sort((a, b) => b.id.compareTo(a.id));
    } else {
      source.sort((a, b) {
        final byLike = b.likeCount.compareTo(a.likeCount);
        if (byLike != 0) return byLike;
        return b.id.compareTo(a.id);
      });
    }

    final start = page * size;
    if (start >= source.length) {
      return const BoardPostPage(
        posts: [],
        hasNext: false,
      );
    }

    final end = (start + size) > source.length ? source.length : (start + size);
    final pageItems = source.sublist(start, end);

    return BoardPostPage(
      posts: pageItems,
      hasNext: end < source.length,
    );
  }

  static const Map<int, List<PostSummary>> _postsByBoard = {
    1: [
      PostSummary(
        id: 1,
        title: '기숙사 <<< 오지마라',
        content: '화장실 이게 맞나 진짜로',
        postStatus: 'NORMAL',
        viewCount: 120,
        anonymous: true,
        likeCount: 20,
        dislikeCount: 0,
        boardId: 1,
        userId: 10,
        username: '익명',
        commentCount: 12,
      ),
      PostSummary(
        id: 2,
        title: '나 기상.',
        content: '25일 스킵 성공\n아래 틴붕이는 얼른 헤어질 수 있도록 하렴',
        postStatus: 'NORMAL',
        viewCount: 333,
        anonymous: true,
        likeCount: 82,
        dislikeCount: 1,
        boardId: 1,
        userId: 11,
        username: '익명',
        commentCount: 50,
      ),
      PostSummary(
        id: 6,
        title: '오늘 야자 분위기 왜 이럼?',
        content: '다들 시험기간이라 예민한 듯',
        postStatus: 'NORMAL',
        viewCount: 84,
        anonymous: true,
        likeCount: 9,
        dislikeCount: 0,
        boardId: 1,
        userId: 14,
        username: '익명',
        commentCount: 6,
      ),
      PostSummary(
        id: 7,
        title: '내일 체육대회 준비물 뭐 챙겨야 함?',
        content: '물 말고 또 필요한 거 있나',
        postStatus: 'NORMAL',
        viewCount: 58,
        anonymous: true,
        likeCount: 4,
        dislikeCount: 0,
        boardId: 1,
        userId: 15,
        username: '익명',
        commentCount: 2,
      ),
      PostSummary(
        id: 8,
        title: '매점 신메뉴 먹어본 사람',
        content: '생각보다 괜찮던데 가격이 조금 아쉽다',
        postStatus: 'NORMAL',
        viewCount: 91,
        anonymous: false,
        likeCount: 15,
        dislikeCount: 0,
        boardId: 1,
        userId: 16,
        username: '김민수',
        commentCount: 5,
      ),
      PostSummary(
        id: 9,
        title: '우리 반만 담임쌤 숙제 많음?',
        content: '오늘도 프린트 세 장 받았다...',
        postStatus: 'NORMAL',
        viewCount: 140,
        anonymous: true,
        likeCount: 31,
        dislikeCount: 0,
        boardId: 1,
        userId: 17,
        username: '익명',
        commentCount: 14,
      ),
      PostSummary(
        id: 10,
        title: '급식 오늘 맛있었음',
        content: '오랜만에 국이 괜찮았어',
        postStatus: 'NORMAL',
        viewCount: 75,
        anonymous: true,
        likeCount: 7,
        dislikeCount: 0,
        boardId: 1,
        userId: 18,
        username: '익명',
        commentCount: 3,
      ),
      PostSummary(
        id: 11,
        title: '복도 에어컨 너무 추움',
        content: '얇게 입고 왔다가 얼어 죽는 줄',
        postStatus: 'NORMAL',
        viewCount: 43,
        anonymous: true,
        likeCount: 2,
        dislikeCount: 0,
        boardId: 1,
        userId: 19,
        username: '익명',
        commentCount: 1,
      ),
      PostSummary(
        id: 12,
        title: '동아리 홍보 어디에 올림?',
        content: '자유게시판에 써도 되는지 궁금함',
        postStatus: 'NORMAL',
        viewCount: 61,
        anonymous: false,
        likeCount: 6,
        dislikeCount: 0,
        boardId: 1,
        userId: 30,
        username: '박서준',
        commentCount: 4,
      ),
      PostSummary(
        id: 13,
        title: '시험 끝나고 뭐할 거냐',
        content: '나는 일단 잠부터 잘 예정',
        postStatus: 'NORMAL',
        viewCount: 105,
        anonymous: true,
        likeCount: 19,
        dislikeCount: 0,
        boardId: 1,
        userId: 31,
        username: '익명',
        commentCount: 7,
      ),
      PostSummary(
        id: 14,
        title: '학교 와이파이 또 느림',
        content: '과제 제출할 때만 이러는 느낌임',
        postStatus: 'NORMAL',
        viewCount: 87,
        anonymous: true,
        likeCount: 13,
        dislikeCount: 0,
        boardId: 1,
        userId: 32,
        username: '익명',
        commentCount: 9,
      ),
    ],
    2: [
      PostSummary(
        id: 3,
        title: '수학 질문 있어요',
        content: '이 문제 접근이 이해가 안 됩니다.',
        postStatus: 'NORMAL',
        viewCount: 49,
        anonymous: true,
        likeCount: 5,
        dislikeCount: 0,
        boardId: 2,
        userId: 20,
        username: '익명',
        commentCount: 3,
      ),
      PostSummary(
        id: 15,
        title: '영어 모의고사 문법 질문',
        content: '5번 보기 왜 정답인지 설명 가능?',
        postStatus: 'NORMAL',
        viewCount: 40,
        anonymous: true,
        likeCount: 3,
        dislikeCount: 0,
        boardId: 2,
        userId: 33,
        username: '익명',
        commentCount: 2,
      ),
    ],
    3: [
      PostSummary(
        id: 4,
        title: '급식 앱 링크 공유',
        content: '급식표 확인 가능한 링크입니다.',
        postStatus: 'NORMAL',
        viewCount: 77,
        anonymous: false,
        likeCount: 14,
        dislikeCount: 0,
        boardId: 3,
        userId: 21,
        username: '김민수',
        commentCount: 4,
      ),
    ],
    4: [
      PostSummary(
        id: 5,
        title: '오늘 토론 주제 어떻게 생각함?',
        content: '청소년 정치 참여 확대에 대한 의견 궁금함.',
        postStatus: 'NORMAL',
        viewCount: 66,
        anonymous: true,
        likeCount: 9,
        dislikeCount: 1,
        boardId: 4,
        userId: 22,
        username: '익명',
        commentCount: 8,
      ),
    ],
  };
}