import 'dart:ui';

import 'package:flutter/material.dart';

const double kGlassBottomBarHeight = 76;
const double kGlassBottomBarMargin = 16;
const double _kIconZoneHeight = 40;
const double _kItemGap = 4;
const double _kLabelHeight = 14;
const double _kIndicatorSize = _kIconZoneHeight + _kItemGap + _kLabelHeight;
const double _kBarVerticalPadding = 6;
const double _kBarHorizontalPadding = 8;

/// 스크롤 콘텐츠가 플로팅 하단바에 가려지지 않도록 확보해야 하는 하단 여백.
double glassBottomBarClearance(BuildContext context) =>
    kGlassBottomBarHeight + kGlassBottomBarMargin * 2 + MediaQuery.of(context).padding.bottom;

class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, kGlassBottomBarMargin + bottomSafeArea),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kGlassBottomBarHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: kGlassBottomBarHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(kGlassBottomBarHeight / 2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kBarHorizontalPadding,
                vertical: _kBarVerticalPadding,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / destinations.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        left: selectedIndex * itemWidth + (itemWidth - _kIndicatorSize) / 2,
                        top: 0,
                        width: _kIndicatorSize,
                        height: _kIndicatorSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            SizedBox(
                              width: itemWidth,
                              child: _GlassNavItem(
                                destination: destinations[i],
                                selected: i == selectedIndex,
                                onTap: () => onDestinationSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 인디케이터가 항상 흰색이므로, 테마와 무관하게 흰 배경에서 또렷한 고정 색을 사용한다.
    const activeColor = Colors.indigo;
    const inactiveColor = Colors.black54;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Semantics(
        label: destination.label,
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _kIconZoneHeight,
                child: Center(
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 22,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
              ),
              const SizedBox(height: _kItemGap),
              SizedBox(
                height: _kLabelHeight,
                child: Center(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.0,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? activeColor : inactiveColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
