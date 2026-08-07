import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/admin_dashboard_api.dart';
import '../../core/api_client.dart';
import '../../models/dashboard.dart';
import '../../widgets/glass_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = AdminDashboardApi(ApiClient.instance);
  final _dateFormat = DateFormat('MM.dd HH:mm');

  int _days = 7;
  bool _loading = true;
  String? _errorMessage;
  List<VisitorTrendPoint> _visitorTrend = [];
  List<BoardActivityPoint> _boardDistribution = [];
  List<RoleDistributionPoint> _roleDistribution = [];
  List<AdminActivityLogItem> _activities = [];

  static const _roleColors = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _api.getVisitorTrend(days: _days),
        _api.getBoardDistribution(days: _days),
        _api.getRoleDistribution(),
        _api.getActivities(),
      ]);
      setState(() {
        _visitorTrend = results[0] as List<VisitorTrendPoint>;
        _boardDistribution = results[1] as List<BoardActivityPoint>;
        _roleDistribution = results[2] as List<RoleDistributionPoint>;
        _activities = results[3] as List<AdminActivityLogItem>;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMembers = _roleDistribution.fold<int>(0, (sum, r) => sum + r.count);
    final todayVisitors = _visitorTrend.isNotEmpty ? _visitorTrend.last.visitorCount : 0;
    final boardActivityTotal = _boardDistribution.fold<int>(0, (sum, b) => sum + b.activityCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 대시보드'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (v) {
              setState(() => _days = v);
              _load();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 7, child: Text('최근 7일')),
              PopupMenuItem(value: 30, child: Text('최근 30일')),
              PopupMenuItem(value: 90, child: Text('최근 90일')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('불러오기에 실패했습니다: $_errorMessage'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _StatCard(label: '총 회원 수', value: '$totalMembers명'),
                      _StatCard(label: '최근 방문자', value: '$todayVisitors명'),
                      _StatCard(label: '게시판 활동($_days일)', value: '$boardActivityTotal건'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('방문자 추이', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildVisitorChart(),
                  const SizedBox(height: 24),
                  Text('게시판별 활동', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildBoardBars(),
                  const SizedBox(height: 24),
                  Text('회원 권한 분포', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildRolePie(),
                  const SizedBox(height: 24),
                  Text('최근 활동', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._activities.map(
                    (a) => ListTile(
                      dense: true,
                      title: Text('${a.username}님이 ${a.message}'),
                      subtitle: Text(_dateFormat.format(DateTime.tryParse(a.createdAt) ?? DateTime.now())),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVisitorChart() {
    if (_visitorTrend.isEmpty) {
      return const Text('데이터가 없습니다.');
    }
    final spots = <FlSpot>[
      for (var i = 0; i < _visitorTrend.length; i++) FlSpot(i.toDouble(), _visitorTrend[i].visitorCount.toDouble()),
    ];
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardBars() {
    if (_boardDistribution.isEmpty) {
      return const Text('데이터가 없습니다.');
    }
    final top = _boardDistribution.take(8).toList();
    final maxCount = top.map((b) => b.activityCount).fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: top
          .map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 90, child: Text(b.boardName, overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: b.activityCount / maxCount,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${b.activityCount}'),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRolePie() {
    if (_roleDistribution.isEmpty) {
      return const Text('데이터가 없습니다.');
    }
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  for (var i = 0; i < _roleDistribution.length; i++)
                    PieChartSectionData(
                      value: _roleDistribution[i].count.toDouble(),
                      title: '${_roleDistribution[i].count}',
                      color: _roleColors[i % _roleColors.length],
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _roleDistribution.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, color: _roleColors[i % _roleColors.length]),
                        const SizedBox(width: 6),
                        Text(_roleDistribution[i].roleName, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
