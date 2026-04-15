import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../school/models/post_summary.dart';
import '../provider/search_provider.dart';

/// 검색 페이지
class SearchPage extends ConsumerStatefulWidget {
  final String? initialKeyword;

  const SearchPage({
    super.key,
    this.initialKeyword,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialKeyword ?? '');
    _focusNode = FocusNode();

    Future.microtask(() async {
      final notifier = ref.read(searchProvider.notifier);

      /// 검색 페이지에 새로 들어왔고 초기 검색어가 없으면 검색 결과 화면을 초기화
      if (_controller.text.trim().isEmpty) {
        notifier.resetSearchView();
      }

      /// 최근 검색어를 먼저 불러옴
      await notifier.loadRecentKeywords();
      notifier.setKeyword(_controller.text);

      /// 초기 키워드가 있으면 바로 검색
      if (_controller.text.trim().isNotEmpty) {
        await notifier.search();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 검색 버튼 또는 엔터 입력 시 검색 수행
  Future<void> _submitSearch() async {
    ref.read(searchProvider.notifier).setKeyword(_controller.text);
    await ref.read(searchProvider.notifier).search();
    setState(() {});
  }

  /// 검색창 내용을 모두 지움
  void _clearSearchInput() {
    _controller.clear();
    ref.read(searchProvider.notifier).setKeyword('');
    ref.read(searchProvider.notifier).resetSearchView();
    setState(() {});
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    ref.listen(searchProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    /// 이전 화면으로 이동
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/school');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          notifier.setKeyword(value);
                          setState(() {});
                        },

                        /// 엔터 입력 시 검색 수행
                        onSubmitted: (_) async {
                          await _submitSearch();
                        },
                        decoration: InputDecoration(
                          hintText: '제목, 본문으로 검색',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9AA7B2),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF7D8790),
                          ),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                            onPressed: _clearSearchInput,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF7D8790),
                            ),
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    /// 검색 버튼 클릭 시 검색 수행
                    onPressed: state.isLoading ? null : _submitSearch,
                    child: const Text(
                      '검색',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Text(
              state.hasSearched
                  ? '"${state.keyword}" 검색 결과'
                  : '제목이나 본문에서 키워드를 검색해보세요.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6E7A86),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : !state.hasSearched
                ? _RecentSearchSection(
              isLoadingRecent: state.isLoadingRecent,
              recentKeywords: state.recentKeywords,
              onKeywordTap: (keyword) async {
                _controller.text = keyword;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                setState(() {});
                await notifier.searchWithKeyword(keyword);
              },
              onDeleteKeyword: (keyword) async {
                await notifier.removeRecentKeyword(keyword);
              },
              onClearAll: () async {
                await notifier.clearRecentKeywords();
              },
            )
                : state.results.isEmpty
                ? const _SearchEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              itemCount: state.results.length + 1,
              separatorBuilder: (context, index) {
                if (index < state.results.length - 1) {
                  return const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFD5DDE6),
                    indent: 12,
                    endIndent: 12,
                  );
                }
                return const SizedBox.shrink();
              },
              itemBuilder: (context, index) {
                if (index < state.results.length) {
                  final post = state.results[index];

                  return Container(
                    color: const Color(0xFFEFF4F9),
                    child: _SearchResultCard(
                      post: post,
                      keyword: state.keyword,

                      /// 검색 결과 게시글 클릭 시 상세 페이지로 이동
                      onTap: () {
                        context.push('/post/${post.id}');
                      },
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _LoadMoreSection(
                    hasNext: state.hasNext,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: () {
                      notifier.loadMore();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 검색 결과 전용 카드
class _SearchResultCard extends StatelessWidget {
  final PostSummary post;
  final String keyword;
  final VoidCallback? onTap;

  const _SearchResultCard({
    required this.post,
    required this.keyword,
    this.onTap,
  });

  String get _likeText {
    if (post.likeCount >= 100) return '100+';
    return '${post.likeCount}';
  }

  String get _commentText {
    if (post.commentCount >= 50) return '50+';
    return '${post.commentCount}';
  }

  String get _timeText {
    switch (post.id % 6) {
      case 0:
        return '10/13';
      case 1:
        return '2분 전';
      case 2:
        return '2시간 전';
      case 3:
        return '12/25';
      case 4:
        return '12/24';
      default:
        return '12/23';
    }
  }

  bool get _showThumbnailBox => post.id % 3 == 1;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showThumbnailBox) ...[
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: post.title,
                    keyword: keyword,
                    maxLines: 2,
                    defaultStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                      height: 1.2,
                    ),
                    highlightStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0E9BFF),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _HighlightedText(
                    text: post.content,
                    keyword: keyword,
                    maxLines: 3,
                    defaultStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF222222),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    highlightStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E9BFF),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _timeText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E8E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '|',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC3C3C3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.displayAuthorName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E8E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _MetaText(
                        icon: Icons.favorite_border_rounded,
                        text: _likeText,
                        color: const Color(0xFFFF8E98),
                      ),
                      const SizedBox(width: 10),
                      _MetaText(
                        icon: Icons.chat_bubble_outline_rounded,
                        text: _commentText,
                        color: const Color(0xFF66BFF5),
                      ),
                    ],
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

/// 검색어 포함 부분만 강조해서 보여주는 텍스트 위젯
class _HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle defaultStyle;
  final TextStyle highlightStyle;
  final int maxLines;

  const _HighlightedText({
    required this.text,
    required this.keyword,
    required this.defaultStyle,
    required this.highlightStyle,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: defaultStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = trimmedKeyword.toLowerCase();

    if (!lowerText.contains(lowerKeyword)) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: defaultStyle,
      );
    }

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerKeyword, start);
      if (index < 0) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: defaultStyle,
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: defaultStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + trimmedKeyword.length),
          style: highlightStyle,
        ),
      );

      start = index + trimmedKeyword.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}

/// 좋아요/댓글 수 표시용 메타 텍스트 위젯
class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaText({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 최근 검색어 섹션
class _RecentSearchSection extends StatelessWidget {
  final bool isLoadingRecent;
  final List<String> recentKeywords;
  final ValueChanged<String> onKeywordTap;
  final ValueChanged<String> onDeleteKeyword;
  final VoidCallback onClearAll;

  const _RecentSearchSection({
    required this.isLoadingRecent,
    required this.recentKeywords,
    required this.onKeywordTap,
    required this.onDeleteKeyword,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recentKeywords.isEmpty) {
      return const _SearchInitialState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            const Text(
              '최근 검색어',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const Spacer(),
            TextButton(
              /// 최근 검색어 전체 삭제
              onPressed: onClearAll,
              child: const Text(
                '전체 삭제',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7D8790),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentKeywords.map(
              (keyword) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2EAF0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    /// 최근 검색어 탭 시 바로 검색
                    onTap: () => onKeywordTap(keyword),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: Color(0xFF7D8790),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            keyword,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  /// 특정 최근 검색어 삭제
                  onPressed: () => onDeleteKeyword(keyword),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF8D98A3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 검색 전 초기 안내 상태
class _SearchInitialState extends StatelessWidget {
  const _SearchInitialState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '최근 검색어가 없어요.\n찾고 싶은 게시글의 제목이나 본문 키워드를 입력해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF7D8790),
          ),
        ),
      ),
    );
  }
}

/// 검색 결과가 없을 때 표시되는 상태
class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '검색 결과가 없어요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7D8790),
          ),
        ),
      ),
    );
  }
}

/// 더보기 / 로딩 / 마지막 상태 영역
class _LoadMoreSection extends StatelessWidget {
  final bool hasNext;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _LoadMoreSection({
    required this.hasNext,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    if (!hasNext) {
      return const SizedBox(height: 16);
    }

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        /// 다음 페이지 검색 결과를 불러옴
        onPressed: onLoadMore,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD6DEE7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          '검색 결과 더보기',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF5C6975),
          ),
        ),
      ),
    );
  }
}