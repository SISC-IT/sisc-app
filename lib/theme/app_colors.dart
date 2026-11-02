import 'package:flutter/material.dart';

/// 앱 전체 라이트 테마 색상 토큰. 홈 탭 디자인(밝은 배경 · 흰 카드 · 파란 포인트)을 기준으로 삼았다.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFFF2F4F8);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFEEF0F4);
  static const Color blue = Color(0xFF2F6FED);
  static const Color blueSoft = Color(0xFFEAF1FE);
  static const Color textPrimary = Color(0xFF171B22);
  static const Color textSecondary = Color(0xFF6E7480);
  static const Color up = Color(0xFFE0333D);
  static const Color down = Color(0xFF1FA971);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8)),
  ];
}
