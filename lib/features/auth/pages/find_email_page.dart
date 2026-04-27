import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../provider/find_email_provider.dart';

class FindEmailPage extends ConsumerStatefulWidget {
  const FindEmailPage({super.key});

  @override
  ConsumerState<FindEmailPage> createState() => _FindEmailPageState();
}

class _FindEmailPageState extends ConsumerState<FindEmailPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    return name.isNotEmpty && RegExp(r'^010\d{8}$').hasMatch(phone);
  }

  Future<void> _submit() async {
    await ref.read(findEmailProvider.notifier).findEmail(
          username: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

    if (!mounted) return;

    final result = ref.read(findEmailProvider).maskedEmail;
    if (result != null) {
      context.push(AppRoutes.findEmailResult, extra: result);
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: Icon(icon, color: const Color(0xFF7A7A7A)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E7EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E7EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4A67F2), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findEmailProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (_canSubmit && !state.isLoading) ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A67F2),
              disabledBackgroundColor: const Color(0xFFD7DEFF),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              state.isLoading ? '조회 중...' : '아이디 찾기',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () { if (context.canPop()) context.pop(); },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              const SizedBox(height: 16),

              const Text(
                '아이디 찾기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '가입할 때 입력한\n이름과 전화번호를 입력해주세요.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.5,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '입력한 정보와 일치하는 아이디를 알려드릴게요.',
                style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF555555)),
              ),

              const SizedBox(height: 32),

              const Text(
                '이름',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  hintText: '이름을 입력해주세요.',
                  icon: Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                '휴대폰 번호',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canSubmit && !state.isLoading) _submit();
                },
                decoration: _inputDecoration(
                  hintText: '예: 01012345678',
                  icon: Icons.phone_iphone_rounded,
                ),
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
