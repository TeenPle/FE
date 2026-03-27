import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../form/board_tab_bar.dart';
import '../provider/home_providers.dart';
import 'widgets/post_summary_card.dart';
import 'widgets/school_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeProvider.notifier).loadInitialHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      floatingActionButton: SizedBox(
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: () {
            debugPrint('글쓰기 페이지로 이동');
          },
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
          SchoolHeader(
            schoolName: state.schoolName.isEmpty ? '학교 로딩 중...' : state.schoolName,
          ),
          BoardTabBar(
            boards: state.boards,
            selectedBoardId: state.selectedBoardId,
            onBoardSelected: (boardId) {
              ref.read(homeProvider.notifier).selectBoard(boardId);
            },
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.errorMessage != null && state.posts.isEmpty) {
                  return Center(
                    child: Text(state.errorMessage!),
                  );
                }

                if (state.posts.isEmpty) {
                  return const Center(
                    child: Text('게시글이 없습니다.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
                    return PostSummaryCard(
                      post: post,
                      onTap: () {
                        debugPrint('post tapped: ${post.id}');
                      },
                    );
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