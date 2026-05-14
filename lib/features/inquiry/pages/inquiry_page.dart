import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../models/inquiry_model.dart';
import '../provider/inquiry_provider.dart';

class InquiryPage extends ConsumerStatefulWidget {
  const InquiryPage({super.key});

  @override
  ConsumerState<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends ConsumerState<InquiryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(inquiryListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inquiryListProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '문의하기',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inquiryListProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _InquiryEntryCard(
              onTap: () async {
                final created = await context.push<bool>(
                  AppRoutes.inquiryWrite,
                );
                if (created == true && context.mounted) {
                  ref.read(inquiryListProvider.notifier).load();
                }
              },
            ),
            const SizedBox(height: 18),
            Text(
              '내 문의 내역',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            if (state.isLoading && state.inquiries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null)
              _InquiryEmptyState(text: state.error!)
            else if (state.inquiries.isEmpty)
              const _InquiryEmptyState(text: '아직 문의 내역이 없어요.')
            else
              ...state.inquiries.map(
                (inquiry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InquiryListTile(
                    inquiry: inquiry,
                    onTap: () async {
                      await context.push(
                        AppRoutes.inquiryDetail(inquiry.inquiryId),
                      );
                      if (context.mounted) {
                        ref.read(inquiryListProvider.notifier).load();
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InquiryEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _InquiryEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.borderStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.tintBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF14A3F7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새 문의 작성',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '앱 이용 중 불편한 점을 남겨주세요.',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
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

class _InquiryListTile extends StatelessWidget {
  final InquirySummaryModel inquiry;
  final VoidCallback onTap;

  const _InquiryListTile({required this.inquiry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _InquiryStatusBadge(inquiry: inquiry),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo(inquiry.createdAt),
                          style: TextStyle(fontSize: 11, color: c.textTertiary),
                        ),
                      ],
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

class _InquiryStatusBadge extends StatelessWidget {
  final InquirySummaryModel inquiry;

  const _InquiryStatusBadge({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final answered = inquiry.isAnswered;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: answered ? c.tintBg : c.subtleBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: answered ? c.borderBlue : c.border),
      ),
      child: Text(
        inquiry.statusLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: answered ? const Color(0xFF14A3F7) : c.textMuted,
        ),
      ),
    );
  }
}

class _InquiryEmptyState extends StatelessWidget {
  final String text;

  const _InquiryEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: c.textMuted),
      ),
    );
  }
}
