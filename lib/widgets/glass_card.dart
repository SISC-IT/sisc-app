import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Material [Card]를 대체하는 공용 카드.
/// 홈 탭과 동일한 불투명 흰 카드 + 옅은 보더/그림자 스타일을 쓴다.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: child,
      ),
    );
  }
}
