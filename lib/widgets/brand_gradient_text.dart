import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 홈 탭에서만 쓰이던 그라디언트 히어로 문구를 재사용 가능한 위젯으로 뺀 것.
/// 로그인 화면 등 "이 앱임을 알아야 하는" 지점에서 같은 브랜드 모먼트를 재사용한다.
class BrandGradientText extends StatelessWidget {
  const BrandGradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.stops,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors.heroGradient;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: colors,
        stops: stops ?? const [0.19, 0.49, 0.59, 1.0],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}
