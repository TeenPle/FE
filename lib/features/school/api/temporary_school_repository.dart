import '../models/board_model.dart';
import '../models/post_summary.dart';
import '../models/school_response.dart';
import 'school_repository.dart';

class TemporarySchoolRepository implements SchoolRepository {
  const TemporarySchoolRepository();

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

    return SchoolResponse(
      schoolId: schoolId,
      name: '틴플고등학교',
      description: '학교 설명',
      boards: boards,
      posts: _postsByBoard[1] ?? const [],
      hasNext: false,
    );
  }

  @override
  Future<List<PostSummary>> getPostsByBoard({
    required int boardId,
    int page = 0,
    int size = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _postsByBoard[boardId] ?? const [];
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