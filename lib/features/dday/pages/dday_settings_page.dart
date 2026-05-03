import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dday_model.dart';
import '../provider/dday_provider.dart';

class DDaySettingsPage extends ConsumerWidget {
  const DDaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ddays = ref.watch(ddayProvider);
    final notifier = ref.read(ddayProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        title: const Text(
          'D-Day 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: ddays.length < 10
          ? FloatingActionButton(
              onPressed: () => _showEditDialog(context, ref, null),
              backgroundColor: const Color(0xFF4A67F2),
              foregroundColor: Colors.white,
              elevation: 0,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: ddays.isEmpty
          ? _EmptyState(
              onAdd: () => _showEditDialog(context, ref, null),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: ddays.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _DDayTile(
                dday: ddays[i],
                onEdit: () => _showEditDialog(context, ref, ddays[i]),
                onDelete: () => notifier.remove(ddays[i].id),
              ),
            ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    DDayModel? existing,
  ) async {
    final notifier = ref.read(ddayProvider.notifier);
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    DateTime selectedDate = existing?.targetDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              existing == null ? 'D-Day 추가' : 'D-Day 수정',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelCtrl,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: '이름 (예: 수능, 기말고사)',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '날짜',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Color(0xFF4A67F2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final label = labelCtrl.text.trim();
                  if (label.isEmpty) return;
                  if (existing == null) {
                    notifier.add(DDayModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: label,
                      targetDate: selectedDate,
                    ));
                  } else {
                    notifier.update(existing.copyWith(
                      label: label,
                      targetDate: selectedDate,
                    ));
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A67F2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(existing == null ? '추가' : '저장'),
              ),
            ],
          );
        },
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF3)),
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
            child: Center(
              child: Text(
                dday.dDayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dday.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dday.targetDate.year}.${dday.targetDate.month.toString().padLeft(2, '0')}.${dday.targetDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9AA7B2),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: const Color(0xFF9AA7B2),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 52,
            color: Color(0xFFB0BEC5),
          ),
          const SizedBox(height: 14),
          const Text(
            'D-Day가 없어요',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '수능, 시험일 등 중요한 날짜를 추가해보세요.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9AA7B2)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('D-Day 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A67F2),
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
