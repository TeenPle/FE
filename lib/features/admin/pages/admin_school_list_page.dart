import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/admin_content_model.dart';
import '../provider/admin_content_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminSchoolListPage extends ConsumerStatefulWidget {
  const AdminSchoolListPage({super.key});

  @override
  ConsumerState<AdminSchoolListPage> createState() =>
      _AdminSchoolListPageState();
}

class _AdminSchoolListPageState extends ConsumerState<AdminSchoolListPage> {
  static const _searchDebounceDuration = Duration(milliseconds: 250);

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminSchoolListProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
      body: SafeArea(
        child: AdminContentFrame(
          child: Column(
            children: [
              const AdminPageHeader(
                title: '학교 모니터링',
                subtitle: '학교별 게시판과 콘텐츠 상태를 확인합니다.',
              ),
              Padding(
                padding: AdminLayout.pagePadding(context, top: 16, bottom: 6),
                child: _SchoolSearchHeader(
                  keyword: state.keyword,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: '학교명 검색',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      ),
                      filled: true,
                      fillColor: c.subtleBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF1477F8),
                          width: 1.4,
                        ),
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
                            ? ListView(
                                padding: AdminLayout.pagePadding(context),
                                children: [
                                  _AdminEmptyCard(
                                    icon: Icons.search_off_rounded,
                                    message: '검색 결과가 없습니다.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                padding: AdminLayout.pagePadding(context),
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
        ),
      ),
    );
  }

  void _search(String keyword) {
    _searchDebounce?.cancel();
    ref.read(adminSchoolListProvider.notifier).load(keyword: keyword.trim());
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onSearchChanged(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      _search(keyword);
    });
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2447).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border.all(color: c.borderBlue),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2447).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1477F8).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF1477F8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      school.regionName ?? '지역 정보 없음',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: c.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: c.iconSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminEmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _AdminEmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: c.iconSecondary),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
