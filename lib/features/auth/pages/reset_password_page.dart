import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_bottom_action_area.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reset_password_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String verificationToken;

  const ResetPasswordPage({super.key, required this.verificationToken});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$',
  );

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isValidPassword => _passwordRegex.hasMatch(_newCtrl.text);

  bool get _isPasswordMatch =>
      _newCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;

  bool get _canSubmit => _isValidPassword && _isPasswordMatch;

  Future<void> _submit() async {
    await ref
        .read(resetPasswordProvider.notifier)
        .resetPassword(
          verificationToken: widget.verificationToken,
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;

    if (ref.read(resetPasswordProvider).isSuccess) {
      context.go('${AppRoutes.login}?reset=success');
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final c = context.colors;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: c.textHint, fontSize: 12),
      filled: true,
      fillColor: c.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: Icon(
        Icons.lock_outline_rounded,
        color: context.colors.iconSecondary,
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: context.colors.iconSecondary,
          size: 20,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF4A67F2), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);

    return Scaffold(
      backgroundColor: context.colors.pageBg,
      bottomNavigationBar: AuthBottomActionArea(
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
            child: state.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '비밀번호 변경',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                splashRadius: 22,
              ),

              SizedBox(height: 16),

              Text(
                '비밀번호 재설정',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67F2),
                ),
              ),

              SizedBox(height: 8),

              Text(
                '새 비밀번호를\n설정해주세요.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.5,
                  color: context.colors.textPrimary,
                ),
              ),

              SizedBox(height: 10),

              Text(
                '영문, 숫자, 특수문자 포함 8~20자로 입력해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.colors.textBody,
                ),
              ),

              SizedBox(height: 32),

              Text(
                '새 비밀번호',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                obscureText: _obscureNew,
                controller: _newCtrl,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  context,
                  hintText: '새 비밀번호를 입력해주세요.',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),

              if (_newCtrl.text.isNotEmpty && !_isValidPassword) ...[
                SizedBox(height: 8),
                Text(
                  '영문, 숫자, 특수문자를 포함한 8~20자로 입력해주세요.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],

              SizedBox(height: 20),

              Text(
                '새 비밀번호 확인',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                obscureText: _obscureConfirm,
                controller: _confirmCtrl,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canSubmit && !state.isLoading) _submit();
                },
                decoration: _inputDecoration(
                  context,
                  hintText: '비밀번호를 한 번 더 입력해주세요.',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              if (_confirmCtrl.text.isNotEmpty && !_isPasswordMatch) ...[
                SizedBox(height: 8),
                Text(
                  '비밀번호가 일치하지 않습니다.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],

              if (state.errorMessage != null) ...[
                SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
