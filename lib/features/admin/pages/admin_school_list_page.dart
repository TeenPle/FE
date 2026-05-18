import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/admin_content_model.dart';
import '../provider/admin_content_provider.dart';

class AdminSchoolListPage extends ConsumerStatefulWidget {
  const AdminSchoolListPage({super.key});

  @override
  ConsumerState<AdminSchoolListPage> createState() =>
      _AdminSchoolListPageState();
}

class _AdminSchoolListPageState extends ConsumerState<AdminSchoolListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminSchoolListProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(adminSchoolListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSchoolListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          '학교 모니터링',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: _SchoolSearchHeader(
              keyword: state.keyword,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: '학교명 검색',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(adminSchoolListProvider.notifier).load();
                      // 검색 초기화 시 목록 상단으로 복귀
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0);
                      }
                    },
                  ),
                  filled: true,
                  fillColor: c.subtleBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.schools.isEmpty
                ? Center(
                    child: Text(
                      state.error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(adminSchoolListProvider.notifier)
                        .load(keyword: state.keyword),
                    child: state.schools.isEmpty
                        // 검색 결과 없음 안내 (pull-to-refresh 작동을 위해 ListView 사용)
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text(
                                    '검색 결과가 없습니다.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: c.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                state.schools.length +
                                (state.isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index >= state.schools.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _SchoolTile(
                                school: state.schools[index],
                                onTap: () => context.push(
                                  AppRoutes.adminSchoolBoards(
                                    state.schools[index].id,
                                  ),
                                  extra: {
                                    'schoolName': state.schools[index].name,
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _search(String keyword) {
    ref.read(adminSchoolListProvider.notifier).load(keyword: keyword.trim());
    // 검색 결과가 바뀌면 목록 상단으로 이동해야 빈 화면처럼 보이지 않는다.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }
}

class _SchoolSearchHeader extends StatelessWidget {
  final String? keyword;
  final Widget child;

  const _SchoolSearchHeader({required this.keyword, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasKeyword = (keyword ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.tintBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF1477F8),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '학교 모니터링',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasKeyword ? '"$keyword" 검색 결과' : '학교별 게시판과 콘텐츠를 확인합니다.',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  final AdminSchoolModel school;
  final VoidCallback onTap;

  const _SchoolTile({required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: c.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.tintBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school_rounded, color: c.iconOnCard),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school.regionName ?? '지역 정보 없음',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
