import 'dart:ui';

import 'package:flutter/material.dart';

/// 불투명한 기본 [FloatingActionButton] 대신 쓰는 글래스모피즘 FAB.
/// 카드·내비게이션 바와 같은 블러 + 반투명 재질 언어를 공유한다.
class GlassFab extends StatelessWidget {
  const GlassFab({super.key, required this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: primary),
            ),
          ),
        ),
      ),
    );
  }
}
