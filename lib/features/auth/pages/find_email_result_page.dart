import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FindEmailResultPage extends StatelessWidget {
  final String maskedEmail;

  const FindEmailResultPage({super.key, required this.maskedEmail});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.pageBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '아이디 찾기',
          style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '가입된 아이디를\n찾았어요.',
                style: AppTextStyles.displaySmall.copyWith(
                  height: 1.35,
                  letterSpacing: -0.5,
                  color: c.textPrimary,
                ),
              ),

              SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7DEFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이메일 (아이디)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Color(0xFF4A67F2),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      maskedEmail,
                      style: AppTextStyles.titleLarge.copyWith(
                        letterSpacing: -0.3,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Text(
                '보안을 위해 이메일 일부는 가려져 있어요.',
                style: AppTextStyles.captionSmall.copyWith(color: c.textMuted),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A67F2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('로그인하기', style: AppTextStyles.titleSmall),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
