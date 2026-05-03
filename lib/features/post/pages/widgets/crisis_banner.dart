import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 위기 키워드 감지 시 노출하는 위기상담 안내 배너.
class CrisisBanner extends StatelessWidget {
  const CrisisBanner({super.key});

  static const _keywords = [
    '자살', '자해', '죽고싶', '죽고 싶', '죽어버리', '죽어버려',
    '살고싶지않', '살기싫', '삶을끝내', '목숨을끊',
  ];

  static bool containsCrisisKeyword(String text) {
    final lower = text.replaceAll(' ', '');
    return _keywords.any((kw) => lower.contains(kw.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFBDBD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFE05C5C)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '힘드신가요? 혼자 견디지 않아도 됩니다.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB71C1C),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '자살예방상담전화 1393 (24시간)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7D2020),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: '1393'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('1393이 클립보드에 복사되었습니다.')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE05C5C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '1393',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
