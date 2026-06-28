import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dday_model.dart';
import '../provider/dday_provider.dart';

class DDaySettingsPage extends ConsumerWidget {
  const DDaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ddays = ref.watch(ddayProvider);
    final notifier = ref.read(ddayProvider.notifier);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        title: Text('D-Day 관리', style: AppTextStyles.titleLarge),
      ),
      floatingActionButton: ddays.length < 10
          ? FloatingActionButton(
              onPressed: () => _showEditSheet(context, notifier, null),
              backgroundColor: const Color(0xFF229BF3),
              foregroundColor: Colors.white,
              elevation: 0,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: ddays.isEmpty
          ? _EmptyState(onAdd: () => _showEditSheet(context, notifier, null))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: ddays.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _DDayTile(
                dday: ddays[i],
                onEdit: () => _showEditSheet(context, notifier, ddays[i]),
                onDelete: () => notifier.remove(ddays[i].id),
              ),
            ),
    );
  }
}

Future<void> _showEditSheet(
  BuildContext context,
  DDayNotifier notifier,
  DDayModel? existing,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DDayEditSheet(
      existing: existing,
      onSave: (dday) {
        if (existing == null) {
          notifier.add(dday);
        } else {
          notifier.update(dday);
        }
      },
    ),
  );
}

class _DDayEditSheet extends StatefulWidget {
  final DDayModel? existing;
  final ValueChanged<DDayModel> onSave;

  const _DDayEditSheet({required this.existing, required this.onSave});

  @override
  State<_DDayEditSheet> createState() => _DDayEditSheetState();
}

class _DDayEditSheetState extends State<_DDayEditSheet> {
  late final TextEditingController _labelCtrl;
  late DateTime _selectedDate;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _selectedDate = widget.existing?.targetDate ?? DateTime.now();
    _selectedIcon = widget.existing?.iconName ?? 'event';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 18),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'D-Day 수정' : 'D-Day 추가',
                style: AppTextStyles.displaySmall.copyWith(
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '이름',
                style: AppTextStyles.labelMedium.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _labelCtrl,
                maxLength: 20,
                style: AppTextStyles.labelLarge.copyWith(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: '예: 수능, 기말고사, 졸업식',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: c.textMuted,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: c.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF229BF3),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '날짜',
                style: AppTextStyles.labelMedium.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    locale: const Locale('ko', 'KR'),
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    helpText: '날짜 선택',
                    cancelText: '취소',
                    confirmText: '선택',
                    builder: (dialogContext, child) {
                      final baseTheme = Theme.of(dialogContext);
                      final isDark = baseTheme.brightness == Brightness.dark;
                      return Theme(
                        data: baseTheme.copyWith(
                          colorScheme: baseTheme.colorScheme.copyWith(
                            primary: const Color(0xFF229BF3),
                            onPrimary: Colors.white,
                            surface: c.cardBg,
                            onSurface: c.textPrimary,
                          ),
                          datePickerTheme: DatePickerThemeData(
                            backgroundColor: c.cardBg,
                            surfaceTintColor: Colors.transparent,
                            headerBackgroundColor: const Color(0xFF229BF3),
                            headerForegroundColor: Colors.white,
                            headerHeadlineStyle: AppTextStyles.bodyMedium
                                .copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                            headerHelpStyle: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                            dividerColor: c.border,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? const Color(0xFF6EC5FF)
                                  : const Color(0xFF229BF3),
                              textStyle: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        child: Transform.scale(scale: 0.92, child: child!),
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: c.inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF229BF3),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.iconSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '아이콘',
                style: AppTextStyles.labelMedium.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: ddayIconMap.entries.map((entry) {
                  final selected = _selectedIcon == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF229BF3) : c.subtleBg,
                        borderRadius: BorderRadius.circular(14),
                        border: selected ? null : Border.all(color: c.border),
                      ),
                      child: Icon(
                        entry.value,
                        size: 22,
                        color: selected ? Colors.white : c.iconOnCard,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final label = _labelCtrl.text.trim();
                    if (label.isEmpty) return;
                    widget.onSave(
                      DDayModel(
                        id:
                            widget.existing?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        label: label,
                        targetDate: _selectedDate,
                        iconName: _selectedIcon,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF229BF3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isEdit ? '저장하기' : '추가하기',
                    style: AppTextStyles.titleLarge,
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

class _DDayTile extends StatelessWidget {
  final DDayModel dday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DDayTile({
    required this.dday,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final d = dday.daysRemaining;
    final accentColor = d == 0
        ? const Color(0xFFE05C7B)
        : d > 0 && d <= 7
        ? const Color(0xFFFF6B35)
        : d > 0
        ? const Color(0xFF4A67F2)
        : const Color(0xFF9AA7B2);
    final icon = ddayIconMap[dday.iconName] ?? Icons.event_rounded;

    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(icon, size: 22, color: accentColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dday.label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dday.dDayLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dday.targetDate.year}.${dday.targetDate.month.toString().padLeft(2, '0')}.${dday.targetDate.day.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: c.textMuted,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFFE05C5C),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined, size: 52, color: c.iconMuted),
          const SizedBox(height: 14),
          Text(
            'D-Day가 없어요',
            style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '수능, 시험일 등 중요한 날짜를 추가해보세요.',
            style: AppTextStyles.captionLarge.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('D-Day 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF229BF3),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
