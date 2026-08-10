import 'package:flutter/material.dart';

/// 앱 전역에서 재사용하는 시맨틱 컬러 토큰.
///
/// 화면마다 `Colors.red` / `Colors.amber` 등을 즉석에서 다시 고르지 않도록,
/// "이 색이 무엇을 뜻하는가"를 한 곳에서 정의한다. 특히 빨강 계열은
/// 상승(marketRise) · 좋아요(socialLike) · 삭제/탈퇴(destructive)에서
/// 서로 다른 색으로 분리해, 같은 색이 여러 의미를 갖지 않게 한다.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.marketRise,
    required this.marketFall,
    required this.pointValue,
    required this.socialLike,
    required this.destructive,
    required this.heroGradient,
  });

  /// 상승(국내 증시 관례상 빨강) · 수익 · 플러스(+) 값에 사용.
  final Color marketRise;

  /// 하락(국내 증시 관례상 파랑) · 손실 · 마이너스(-) 값에 사용.
  final Color marketFall;

  /// 포인트 등 재화 표시 전용.
  final Color pointValue;

  /// 좋아요 등 소셜 반응 전용. marketRise와 같은 빨강 계열이 아니라
  /// 별도 색상으로 분리해 "상승"과 혼동되지 않게 한다.
  final Color socialLike;

  /// 삭제·탈퇴·거절 등 파괴적 액션과 에러 텍스트 전용.
  final Color destructive;

  /// 홈 탭 히어로 문구 등 브랜드 모먼트에 쓰는 그라디언트.
  final List<Color> heroGradient;

  static const dark = AppColors(
    marketRise: Color(0xFFFF5C5C),
    marketFall: Color(0xFF4C8DFF),
    pointValue: Color(0xFFF5C24D),
    socialLike: Color(0xFFFF6FA8),
    destructive: Color(0xFFE1476B),
    heroGradient: [
      Color(0xFF5B93ED),
      Color(0xFF78B4F3),
      Color(0xFFB2F4FF),
      Color(0xFFFCFFFF),
    ],
  );

  @override
  AppColors copyWith({
    Color? marketRise,
    Color? marketFall,
    Color? pointValue,
    Color? socialLike,
    Color? destructive,
    List<Color>? heroGradient,
  }) {
    return AppColors(
      marketRise: marketRise ?? this.marketRise,
      marketFall: marketFall ?? this.marketFall,
      pointValue: pointValue ?? this.pointValue,
      socialLike: socialLike ?? this.socialLike,
      destructive: destructive ?? this.destructive,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      marketRise: Color.lerp(marketRise, other.marketRise, t)!,
      marketFall: Color.lerp(marketFall, other.marketFall, t)!,
      pointValue: Color.lerp(pointValue, other.pointValue, t)!,
      socialLike: Color.lerp(socialLike, other.socialLike, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
