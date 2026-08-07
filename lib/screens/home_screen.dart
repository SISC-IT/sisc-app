import 'package:flutter/material.dart';

import 'board/board_screen.dart';
import 'home/home_tab.dart';
import 'mypage/mypage_screen.dart';
import 'trading/trading_tab.dart';
import '../state/auth_state.dart';
import '../widgets/glass_bottom_nav_bar.dart';
import 'attendance_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authState});

  final AuthState authState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _tabs = [
    const HomeTab(),
    BoardScreen(authState: widget.authState),
    AttendanceHistoryScreen(authState: widget.authState),
    const TradingTab(),
    MypageScreen(authState: widget.authState),
  ];

  static const _destinations = [
    GlassNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '홈'),
    GlassNavDestination(icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: '게시판'),
    GlassNavDestination(icon: Icons.event_available_outlined, selectedIcon: Icons.event_available, label: '출석'),
    GlassNavDestination(icon: Icons.show_chart_outlined, selectedIcon: Icons.show_chart, label: '트레이딩'),
    GlassNavDestination(icon: Icons.person_outline, selectedIcon: Icons.person, label: '마이페이지'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: GlassBottomNavBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: _destinations,
      ),
    );
  }
}
