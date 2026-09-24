import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../widgets/glass_bottom_nav_bar.dart';

/// 세투연 홈 탭.
/// 깔끔한 금융/투자 앱 톤(밝은 배경 · 흰색 카드 · 파란 포인트 · 둥근 모서리)으로
/// 히어로 / 공지사항 / 오늘의 시장 / 빠른 메뉴 / 다가오는 일정 / 주요 소식 섹션을 담는다.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  static const List<_MarketItem> _markets = [
    _MarketItem(
      name: 'KOSPI',
      value: '2,856.23',
      change: '+12.34',
      changePercent: '+0.43%',
      isUp: true,
      trend: [10, 12, 9, 14, 11, 16, 13, 18, 15, 20],
    ),
    _MarketItem(
      name: 'KOSDAQ',
      value: '842.17',
      change: '+6.21',
      changePercent: '+0.74%',
      isUp: true,
      trend: [8, 10, 7, 11, 9, 13, 10, 15, 12, 16],
    ),
    _MarketItem(
      name: 'S&P 500',
      value: '5,487.03',
      change: '-8.12',
      changePercent: '-0.15%',
      isUp: false,
      trend: [20, 18, 21, 16, 19, 14, 17, 12, 15, 10],
    ),
  ];

  static const List<_QuickMenuItem> _quickMenu = [
    _QuickMenuItem(icon: Icons.bar_chart_rounded, label: '시장 분석'),
    _QuickMenuItem(icon: Icons.school_rounded, label: '스터디 자료'),
    _QuickMenuItem(icon: Icons.event_note_rounded, label: '행사 일정'),
    _QuickMenuItem(icon: Icons.groups_rounded, label: '동아리 소개'),
  ];

  static const List<_EventItem> _events = [
    _EventItem(
      month: 'JUL',
      day: '22',
      title: '주간 투자 스터디',
      tag: '스터디',
      time: '19:00',
      location: '학생회관 세미나실',
    ),
    _EventItem(
      month: 'JUL',
      day: '29',
      title: '전문가 특강: 글로벌 반도체 산업 전망',
      tag: '특강',
      time: '18:30',
      location: '온라인 (Zoom)',
    ),
    _EventItem(
      month: 'AUG',
      day: '05',
      title: '정기 회의',
      tag: '정기모임',
      time: '19:00',
      location: '학생회관 314호',
    ),
  ];

  static const List<_NewsItem> _news = [
    _NewsItem(
      icon: Icons.show_chart_rounded,
      title: '미 연준, 금리 동결... 향후 인하 가능성 시사',
      date: '2025.07.16',
    ),
    _NewsItem(
      icon: Icons.memory_rounded,
      title: 'AI 반도체 시장, 다시 성장 가속화',
      date: '2025.07.15',
    ),
    _NewsItem(
      icon: Icons.rocket_launch_rounded,
      title: '글로벌 우주산업, 새로운 투자 기회로 부상',
      date: '2025.07.14',
    ),
  ];

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label · 준비 중입니다'), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, glassBottomBarClearance(context) + 12),
          children: [
            _HomeHeader(onBellTap: () => _comingSoon(context, '알림')),
            const SizedBox(height: 20),
            const _HeroBanner(),
            const SizedBox(height: 20),
            _NoticeCard(onTap: () => _comingSoon(context, '공지사항')),
            const SizedBox(height: 28),
            _SectionHeader(title: '오늘의 시장', onMore: () => _comingSoon(context, '시장 분석')),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < _markets.length; i++) ...[
                  if (i != 0) const SizedBox(width: 10),
                  Expanded(child: _MarketCard(item: _markets[i])),
                ],
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                for (var i = 0; i < _quickMenu.length; i++)
                  Expanded(
                    child: _QuickMenuButton(
                      item: _quickMenu[i],
                      onTap: () => _comingSoon(context, _quickMenu[i].label),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: '다가오는 일정', onMore: () => _comingSoon(context, '행사 일정')),
            const SizedBox(height: 12),
            _SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < _events.length; i++) ...[
                    if (i != 0) const Divider(height: 1, color: Color(0xFFEEF0F4)),
                    _EventRow(item: _events[i], onTap: () => _comingSoon(context, _events[i].title)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: '주요 소식', onMore: () => _comingSoon(context, '주요 소식')),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _news.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _NewsCard(
                  item: _news[index],
                  onTap: () => _comingSoon(context, _news[index].title),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 디자인 토큰: 밝은 배경 · 흰 카드 · 파란 포인트
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFFF2F4F8);
const Color _kCard = Colors.white;
const Color _kBlue = Color(0xFF2F6FED);
const Color _kBlueSoft = Color(0xFFEAF1FE);
const Color _kTextPrimary = Color(0xFF171B22);
const Color _kTextSecondary = Color(0xFF6E7480);
const Color _kUp = Color(0xFFE0333D);
const Color _kDown = Color(0xFF1FA971);

BoxDecoration _cardDecoration({double radius = 20}) => BoxDecoration(
  color: _kCard,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8)),
  ],
);

// ---------------------------------------------------------------------------
// 상단 헤더 (로고 + 클럽명 + 알림 벨)
// ---------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onBellTap});

  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: Image(
              image: AssetImage('assets/icon/app_icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SISC',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kTextPrimary),
              ),
              Text(
                'Sejong Investment Scholars Club',
                style: TextStyle(fontSize: 11, color: _kTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onBellTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: _cardDecoration(radius: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, color: _kTextPrimary, size: 20),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 히어로 배너
// ---------------------------------------------------------------------------

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  // assets/images/hero_banner.png 원본 비율 (가로 550 × 세로 235).
  static const double _aspectRatio = 550 / 235;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Image.asset(
          'assets/images/hero_banner.png',
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 공지사항
// ---------------------------------------------------------------------------

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _kBlueSoft, shape: BoxShape.circle),
              child: const Icon(Icons.campaign_rounded, color: _kBlue, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('공지사항', style: TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(
                    '세투연 2025 하반기 정기 세미나 안내',
                    style: TextStyle(fontSize: 14, color: _kTextPrimary, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 헤더 ("더보기" 포함)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onMore});

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextPrimary)),
        if (onMore != null)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onMore,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('더보기', style: TextStyle(fontSize: 13, color: _kTextSecondary, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: _kTextSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 공용 흰 카드 컨테이너
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: _cardDecoration(),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// 오늘의 시장 카드
// ---------------------------------------------------------------------------

class _MarketItem {
  const _MarketItem({
    required this.name,
    required this.value,
    required this.change,
    required this.changePercent,
    required this.isUp,
    required this.trend,
  });

  final String name;
  final String value;
  final String change;
  final String changePercent;
  final bool isUp;
  final List<double> trend;
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.item});

  final _MarketItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isUp ? _kUp : _kDown;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kTextSecondary),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(item.isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: color, size: 16),
              Expanded(
                child: Text(
                  '${item.change} (${item.changePercent})',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 28, child: _Sparkline(values: item.trend, color: color)),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])];
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 빠른 메뉴
// ---------------------------------------------------------------------------

class _QuickMenuItem {
  const _QuickMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _QuickMenuButton extends StatelessWidget {
  const _QuickMenuButton({required this.item, required this.onTap});

  final _QuickMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: _kBlueSoft, shape: BoxShape.circle),
              child: Icon(item.icon, color: _kBlue, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 다가오는 일정
// ---------------------------------------------------------------------------

class _EventItem {
  const _EventItem({
    required this.month,
    required this.day,
    required this.title,
    required this.tag,
    required this.time,
    required this.location,
  });

  final String month;
  final String day;
  final String title;
  final String tag;
  final String time;
  final String location;
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.item, required this.onTap});

  final _EventItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: _kBlueSoft, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(item.month, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kBlue)),
                  Text(item.day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kBlue)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _Tag(label: item.tag),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.time} · ${item.location}',
                    style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _kBlueSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kBlue)),
    );
  }
}

// ---------------------------------------------------------------------------
// 주요 소식
// ---------------------------------------------------------------------------

class _NewsItem {
  const _NewsItem({required this.icon, required this.title, required this.date});

  final IconData icon;
  final String title;
  final String date;
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.onTap});

  final _NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kBlueSoft, Colors.white]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: _kBlue, size: 26),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _kTextPrimary, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(item.date, style: const TextStyle(fontSize: 10.5, color: _kTextSecondary)),
          ],
        ),
      ),
    );
  }
}
