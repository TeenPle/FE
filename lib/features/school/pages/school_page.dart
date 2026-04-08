import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../form/board_tab_bar.dart';
import '../provider/school_providers.dart';
import 'widgets/post_summary_card.dart';
import 'widgets/school_header.dart';
import 'package:go_router/go_router.dart';

class SchoolPage extends ConsumerStatefulWidget {
  const SchoolPage({super.key});

  @override
  ConsumerState<SchoolPage> createState() => _SchoolPageState();
}

class _SchoolPageState extends ConsumerState<SchoolPage> {
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(schoolProvider.notifier).loadInitialSchool(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF444444),
        shape: const CircleBorder(),
        child: const Icon(Icons.search, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _bottomIndex,
        onTap: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            SchoolHeader(
              schoolName: state.schoolName.isEmpty ? '학교 로딩 중...' : state.schoolName,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E6EA)),
            BoardTabBar(
              boards: state.boards,
              selectedBoardId: state.selectedBoardId,
              onBoardSelected: (boardId) {
                ref.read(schoolProvider.notifier).selectBoard(boardId);
              },
            ),
            Expanded(
              child: state.isLoading && state.posts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.only(bottom: 130),
                children: [
                  _SectionCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < state.posts.length; i++)
                          PostSummaryCard(
                            post: state.posts[i],
                            showDivider: i != state.posts.length - 1,
                            onTap: () {
                              context.push('/post/${state.posts[i].id}');
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}