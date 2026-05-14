import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../provider/inquiry_provider.dart';

class InquiryWritePage extends ConsumerStatefulWidget {
  const InquiryWritePage({super.key});

  @override
  ConsumerState<InquiryWritePage> createState() => _InquiryWritePageState();
}

class _InquiryWritePageState extends ConsumerState<InquiryWritePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inquiryCreateProvider);
    final c = context.colors;

    ref.listen(inquiryCreateProvider, (_, next) {
      if (next.submitted) {
        ref.read(inquiryCreateProvider.notifier).clearResult();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('문의가 접수되었습니다.')));
        Navigator.of(context).pop(true);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFE05C7B),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '문의 작성',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _InputPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('제목'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(context, '문의 제목을 입력해주세요.'),
                ),
                const SizedBox(height: 14),
                _FieldLabel('내용'),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  minLines: 8,
                  maxLines: 12,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration(context, '문의 내용을 자세히 입력해주세요.'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: state.isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14A3F7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              state.isSubmitting ? '접수 중...' : '문의 접수',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')));
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(inquiryCreateProvider.notifier)
        .submit(title: title, content: content);
  }
}

class _InputPanel extends StatelessWidget {
  final Widget child;

  const _InputPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderStrong),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: context.colors.textPrimary,
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String hintText) {
  final c = context.colors;
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: c.textHint),
    filled: true,
    fillColor: c.subtleBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF14A3F7)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}
