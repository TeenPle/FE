import '../models/board_model.dart';
import '../models/post_summary.dart';
import 'home_repository.dart';

class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  @override
  Future<HomeInitialResult> loadInitialHome() async {
    await Future.delayed(const Duration(milliseconds: 300));

    const boards = [
      BoardModel(id: 1, name: '자유게시판'),
      BoardModel(id: 2, name: '1학년'),
      BoardModel(id: 3, name: '2학년'),
      BoardModel(id: 4, name: '3학년'),
      BoardModel(id: 5, name: '졸업생'),
    ];

    return HomeInitialResult(
      schoolName: '서울고등학교',
      boards: boards,
      defaultBoardId: 1,
      posts: _postsByBoard[1] ?? const [],
    );
  }

  @override
  Future<List<PostSummary>> getPostsByBoard(int boardId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _postsByBoard[boardId] ?? const [];
  }

  static const Map<int, List<PostSummary>> _postsByBoard = {
    1: [
      PostSummary(
        id: 1,
        title: '진로 고민중입니다.. 조언 부탁드려요',
        content: '이과인데 문과로 바꿀까 고민이에요. 수학이 너무 어렵고 국어가 더 재미있어서...',
        username: '익명',
        anonymous: true,
        boardName: '자유게시판',
        createdAt: '3시간 전',
        likeCount: 45,
        dislikeCount: 8,
        commentCount: 38,
        viewCount: 342,
      ),
      PostSummary(
        id: 2,
        title: '동아리 추천 부탁드려요',
        content: '올해 동아리 뭐 들어갈지 고민중인데 추천해주세요! 운동계열이나 학술계열 다 좋아요.',
        username: '박지훈',
        anonymous: false,
        boardName: '자유게시판',
        createdAt: '6시간 전',
        likeCount: 12,
        dislikeCount: 0,
        commentCount: 31,
        viewCount: 178,
      ),
    ],
    2: [
      PostSummary(
        id: 3,
        title: '1학년 시간표 적응 어렵다',
        content: '생각보다 이동수업이 많아서 정신이 없네요. 다들 적응 어떻게 했어요?',
        username: '익명',
        anonymous: true,
        boardName: '1학년',
        createdAt: '1시간 전',
        likeCount: 9,
        dislikeCount: 1,
        commentCount: 5,
        viewCount: 54,
      ),
    ],
    3: [
      PostSummary(
        id: 4,
        title: '수학 선택과목 뭐가 나아요?',
        content: '미적분이랑 확통 중에서 고민중인데 조언 좀 부탁합니다.',
        username: '익명',
        anonymous: true,
        boardName: '2학년',
        createdAt: '50분 전',
        likeCount: 20,
        dislikeCount: 2,
        commentCount: 11,
        viewCount: 92,
      ),
    ],
    4: [
      PostSummary(
        id: 5,
        title: '면접 준비 같이 할 사람',
        content: '방과 후에 면접 스터디 같이 할 사람 있으면 댓글 남겨주세요.',
        username: '김민수',
        anonymous: false,
        boardName: '3학년',
        createdAt: '2시간 전',
        likeCount: 17,
        dislikeCount: 0,
        commentCount: 6,
        viewCount: 81,
      ),
    ],
    5: [
      PostSummary(
        id: 6,
        title: '대학교 와서 느낀 점',
        content: '고등학교 때 미리 해두면 좋았던 것들 정리해봅니다.',
        username: '졸업생A',
        anonymous: false,
        boardName: '졸업생',
        createdAt: '어제',
        likeCount: 51,
        dislikeCount: 3,
        commentCount: 25,
        viewCount: 501,
      ),
    ],
  };
}