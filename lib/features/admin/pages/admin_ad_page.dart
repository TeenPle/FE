import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../ad/models/ad_banner_model.dart';
import '../../ad/provider/ad_banner_provider.dart';
import '../widgets/admin_responsive.dart';

class AdminAdPage extends ConsumerStatefulWidget {
  const AdminAdPage({super.key});

  @override
  ConsumerState<AdminAdPage> createState() => _AdminAdPageState();
}

class _AdminAdPageState extends ConsumerState<AdminAdPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminAdListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAdListProvider);
    final notifier = ref.read(adminAdListProvider.notifier);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        title: Text(
          '광고 관리',
          style: AppTextStyles.titleSmall.copyWith(color: c.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('광고 추가'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdminContentFrame(
              child: ListView.separated(
                padding: AdminLayout.pagePadding(context, bottom: 96),
                itemCount: state.ads.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ad = state.ads[index];
                  return _AdAdminTile(
                    ad: ad,
                    onEdit: () => _openEditor(context, ad: ad),
                    onDelete: () => _deleteAd(context, ad.id),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, {AdBannerModel? ad}) async {
    final saved = await showModalBottomSheet<AdBannerModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AdEditorSheet(initial: ad),
    );
    if (saved == null || !mounted) return;

    try {
      await ref.read(adminAdListProvider.notifier).save(saved);
      if (!mounted) return;
      // 활성 광고 캐시는 다음 화면 진입 전에도 즉시 갱신되도록 무효화한다.
      ref.invalidate(activeAdProvider(saved.placement));
      showAppSnackBar('광고를 저장했어요.');
    } catch (_) {
      showAppSnackBar(
        '광고 저장에 실패했어요.',
        backgroundColor: const Color(0xFFE05C7B),
      );
    }
  }

  Future<void> _deleteAd(BuildContext context, int adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('광고 삭제'),
        content: const Text('이 광고를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(adminAdListProvider.notifier).delete(adId);
      ref.invalidate(activeAdProvider);
      showAppSnackBar('광고를 삭제했어요.');
    } catch (_) {
      showAppSnackBar(
        '광고 삭제에 실패했어요.',
        backgroundColor: const Color(0xFFE05C7B),
      );
    }
  }
}

class _AdAdminTile extends StatelessWidget {
  final AdBannerModel ad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdAdminTile({
    required this.ad,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          _PlacementBadge(placement: ad.placement, active: ad.active),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '우선순위 ${ad.priority} · ${ad.active ? '활성' : '비활성'}',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _PlacementBadge extends StatelessWidget {
  final String placement;
  final bool active;

  const _PlacementBadge({required this.placement, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF1477F8)
        : context.colors.iconSecondary;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          placement == 'POST_DETAIL' ? '상세' : '목록',
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AdEditorSheet extends StatefulWidget {
  final AdBannerModel? initial;

  const _AdEditorSheet({this.initial});

  @override
  State<_AdEditorSheet> createState() => _AdEditorSheetState();
}

class _AdEditorSheetState extends State<_AdEditorSheet> {
  late String _placement;
  late bool _active;
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _imageUrl;
  late final TextEditingController _linkUrl;
  late final TextEditingController _priority;
  late final TextEditingController _startAt;
  late final TextEditingController _endAt;

  @override
  void initState() {
    super.initState();
    final ad = widget.initial;
    _placement = ad?.placement ?? 'HOME_FEED';
    _active = ad?.active ?? true;
    _title = TextEditingController(text: ad?.title ?? '');
    _subtitle = TextEditingController(text: ad?.subtitle ?? '');
    _imageUrl = TextEditingController(text: ad?.imageUrl ?? '');
    _linkUrl = TextEditingController(text: ad?.linkUrl ?? '');
    _priority = TextEditingController(text: '${ad?.priority ?? 100}');
    _startAt = TextEditingController(
      text: ad?.startAt?.toIso8601String() ?? '',
    );
    _endAt = TextEditingController(text: ad?.endAt?.toIso8601String() ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    _linkUrl.dispose();
    _priority.dispose();
    _startAt.dispose();
    _endAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initial == null ? '광고 추가' : '광고 수정',
              style: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _placement,
              items: const [
                DropdownMenuItem(value: 'HOME_FEED', child: Text('게시글 목록')),
                DropdownMenuItem(value: 'POST_DETAIL', child: Text('게시글 상세')),
              ],
              onChanged: (value) =>
                  setState(() => _placement = value ?? 'HOME_FEED'),
              decoration: const InputDecoration(labelText: '노출 위치'),
            ),
            SwitchListTile(
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('활성화'),
              contentPadding: EdgeInsets.zero,
            ),
            _TextInput(controller: _title, label: '제목'),
            _TextInput(controller: _subtitle, label: '설명', maxLines: 2),
            _TextInput(controller: _imageUrl, label: '이미지 URL'),
            _TextInput(controller: _linkUrl, label: '클릭 링크 URL'),
            _TextInput(
              controller: _priority,
              label: '우선순위',
              keyboardType: TextInputType.number,
            ),
            _TextInput(controller: _startAt, label: '시작일 ISO 형식(선택)'),
            _TextInput(controller: _endAt, label: '종료일 ISO 형식(선택)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_title.text.trim().isEmpty || _subtitle.text.trim().isEmpty) {
      showAppSnackBar('제목과 설명을 입력해 주세요.');
      return;
    }

    Navigator.pop(
      context,
      AdBannerModel(
        id: widget.initial?.id ?? 0,
        placement: _placement,
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        imageUrl: _blankToNull(_imageUrl.text),
        linkUrl: _blankToNull(_linkUrl.text),
        active: _active,
        priority: int.tryParse(_priority.text.trim()) ?? 100,
        startAt: _parseDate(_startAt.text),
        endAt: _parseDate(_endAt.text),
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : DateTime.tryParse(trimmed);
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextInput({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
