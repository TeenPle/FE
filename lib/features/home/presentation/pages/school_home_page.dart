import 'package:flutter/material.dart';
import '../../model/board_model.dart';
import '../../model/post_summary.dart';
import '../widgets/board_tab_bar.dart';
import '../widgets/post_summary_card.dart';
import '../widgets/school_header.dart';

class SchoolHomePage extends StatefulWidget {
  const SchoolHomePage({super.key});

  @override
  State<SchoolHomePage> createState() => _SchoolHomePageState();
}

class _SchoolHomePageState extends State<SchoolHomePage> {
  final List<BoardModel> _boards = const [
    BoardModel(id: 1, name: '자유게시판'),
    BoardModel(id: 2, name: '1학년'),
    BoardModel(id: 3, name: '2학년'),
    BoardModel(id: 4, name: '3학년'),
    BoardModel(id: 5, name: '졸업생'),
  ];

  int _selectedBoardId = 1;

  late final Map<int, List<PostSummary>> _mockPostsByBoard = {
    1: const [
      PostSummary(
        id: 1,
        authorName: '익명',
        isAnonymous: true,
        boardName: '자유게시판',
        title: '진로 고민중입니다.. 조언 부탁드려요',
        contentPreview: '이과인데 문과로 바꿀까 고민이에요. 수학이 너무 어렵고 국어가 더 재미있어서...',
        createdAt: '3시간 전',
        likeCount: 45,
        dislikeCount: 8,
        commentCount: 38,
        viewCount: 342,
      ),
      PostSummary(
        id: 2,
        authorName: '박지훈',
        isAnonymous: false,
        boardName: '자유게시판',
        title: '동아리 추천 부탁드려요',
        contentPreview: '올해 동아리 뭐 들어갈지 고민중인데 추천해주세요! 운동계열이나 학술계열 다 좋아요.',
        createdAt: '6시간 전',
        likeCount: 12,
        dislikeCount: 0,
        commentCount: 31,
        viewCount: 178,
      ),
    ],
    2: const [
      PostSummary(
        id: 3,
        authorName: '익명',
        isAnonymous: true,
        boardName: '1학년',
        title: '1학년 시간표 적응 어렵다',
        contentPreview: '생각보다 이동수업이 많아서 정신이 없네요. 다들 적응 어떻게 했어요?',
        createdAt: '1시간 전',
        likeCount: 9,
        dislikeCount: 1,
        commentCount: 5,
        viewCount: 54,
      ),
    ],
    3: const [
      PostSummary(
        id: 4,
        authorName: '익명',
        isAnonymous: true,
        boardName: '2학년',
        title: '수학 선택과목 뭐가 나아요?',
        contentPreview: '미적분이랑 확통 중에서 고민중인데 조언 좀 부탁합니다.',
        createdAt: '50분 전',
        likeCount: 20,
        dislikeCount: 2,
        commentCount: 11,
        viewCount: 92,
      ),
    ],
    4: const [
      PostSummary(
        id: 5,
        authorName: '김민수',
        isAnonymous: false,
        boardName: '3학년',
        title: '면접 준비 같이 할 사람',
        contentPreview: '방과 후에 면접 스터디 같이 할 사람 있으면 댓글 남겨주세요.',
        createdAt: '2시간 전',
        likeCount: 17,
        dislikeCount: 0,
        commentCount: 6,
        viewCount: 81,
      ),
    ],
    5: const [
      PostSummary(
        id: 6,
        authorName: '졸업생A',
        isAnonymous: false,
        boardName: '졸업생',
        title: '대학교 와서 느낀 점',
        contentPreview: '고등학교 때 미리 해두면 좋았던 것들 정리해봅니다.',
        createdAt: '어제',
        likeCount: 51,
        dislikeCount: 3,
        commentCount: 25,
        viewCount: 501,
      ),
    ],
  };

  List<PostSummary> get _currentPosts =>
      _mockPostsByBoard[_selectedBoardId] ?? const [];

  void _onBoardSelected(int boardId) {
    setState(() {
      _selectedBoardId = boardId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SizedBox(
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: const Color(0xFF199BFF),
          foregroundColor: Colors.white,
          label: const Text(
            '글쓰기',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
      body: Column(
        children: [
          const SchoolHeader(schoolName: '서울고등학교'),
          BoardTabBar(
            boards: _boards,
            selectedBoardId: _selectedBoardId,
            onBoardSelected: _onBoardSelected,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _currentPosts.length,
              itemBuilder: (context, index) {
                final post = _currentPosts[index];
                return PostSummaryCard(
                  post: post,
                  onTap: () {
                    debugPrint('post tapped: ${post.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}