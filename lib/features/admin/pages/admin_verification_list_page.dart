import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/verification_request_list_item_model.dart';
import '../models/verification_status_model.dart';
import '../provider/admin_verification_list_provider.dart';
import '../widgets/admin_responsive.dart';

/// 관리자 학교 인증 요청 목록 페이지
class AdminVerificationListPage extends ConsumerStatefulWidget {
  const AdminVerificationListPage({super.key});

  @override
  ConsumerState<AdminVerificationListPage> createState() =>
      _AdminVerificationListPageState();
}

class _AdminVerificationListPageState
    extends ConsumerState<AdminVerificationListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
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
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      // 인증 요청도 상태별로 20개씩만 붙인다. 전체 목록 선로딩을 막기 위한 하단 감지 지점이다.
      ref.read(adminVerificationListProvider.notifier).fetchMore();
    }
  }

  void _search(String keyword) {
    _searchDebounce?.cancel();
    ref.read(adminVerificationListProvider.notifier).search(keyword);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onSearchChanged(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _search(keyword);
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '${value.year}.$month.$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminVerificationListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: AdminContentFrame(
          child: Column(
            children: [
              /// 상단 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      splashRadius: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '학교 인증 요청',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// 상단 설명
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    Text(
                      '현재 요청',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.items.length}건',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A67F2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _VerificationSearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _search('');
                  },
                ),
              ),

              /// 상태 필터
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF2F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: VerificationStatusModel.values.map((status) {
                      final isSelected = state.selectedStatus == status;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(adminVerificationListProvider.notifier)
                                .fetchList(status, state.keyword);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4A67F2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              status.label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.items.isEmpty
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: c.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: c.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inbox_rounded,
                                size: 28,
                                color: Color(0xFF9AA3AF),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '조회된 요청이 없어요.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(adminVerificationListProvider.notifier)
                              .fetchList(state.selectedStatus, state.keyword);
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: AdminLayout.pagePadding(
                            context,
                            top: 4,
                            bottom: 24,
                          ),
                          itemCount:
                              state.items.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final item = state.items[index];

                            return _VerificationRequestCard(
                              item: item,
                              formattedDate: _formatDate(item.requestedAt),
                              onTap: () async {
                                final result = await context.push<bool>(
                                  '${AppRoutes.adminVerificationList}/${item.requestId}',
                                );

                                if (result == true) {
                                  ref
                                      .read(
                                        adminVerificationListProvider.notifier,
                                      )
                                      .fetchList(
                                        state.selectedStatus,
                                        state.keyword,
                                      );
                                }
                              },
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
}

class _VerificationRequestCard extends StatelessWidget {
  final VerificationRequestListItemModel item;
  final String formattedDate;
  final VoidCallback onTap;

  const _VerificationRequestCard({
    required this.item,
    required this.formattedDate,
    required this.onTap,
  });

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
                  Icons.badge_outlined,
                  color: Color(0xFF1477F8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.schoolName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: c.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.textBody,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CardMeta(
                      icon: Icons.mail_outline_rounded,
                      text: item.userEmail,
                    ),
                    const SizedBox(height: 6),
                    _CardMeta(
                      icon: Icons.schedule_rounded,
                      text: formattedDate,
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

class _VerificationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _VerificationSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onChanged,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '학교명, 이름, 이메일 검색',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClear,
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
          borderSide: const BorderSide(color: Color(0xFF1477F8), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CardMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 15, color: c.iconSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: c.textSecondary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final VerificationStatusModel status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VerificationStatusModel.pending => const Color(0xFF1477F8),
      VerificationStatusModel.approved => const Color(0xFF2F7D46),
      VerificationStatusModel.rejected => const Color(0xFFE05C7B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}
