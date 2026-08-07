import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/quant_bot_api.dart';
import '../../core/api_client.dart';
import '../../models/quant_bot.dart';
import '../../widgets/glass_card.dart';

class QuantBotScreen extends StatefulWidget {
  const QuantBotScreen({super.key});

  @override
  State<QuantBotScreen> createState() => _QuantBotScreenState();
}

class _QuantBotScreenState extends State<QuantBotScreen> {
  final _api = QuantBotApi(ApiClient.instance);
  final _numberFormat = NumberFormat('#,##0');

  bool _loading = true;
  String? _errorMessage;
  PortfolioOverview? _overview;
  List<AssetPoint> _assets = [];
  List<PositionInfo> _positions = [];
  List<TradeLogInfo> _logs = [];
  String? _selectedDate;

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
        _api.getPortfolioOverview(),
        _api.getAssets(),
        _api.getPositions(),
        _api.getLogs(),
      ]);
      setState(() {
        _overview = results[0] as PortfolioOverview;
        _assets = results[1] as List<AssetPoint>;
        _positions = results[2] as List<PositionInfo>;
        _logs = results[3] as List<TradeLogInfo>;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReport(TradeLogInfo log) async {
    if (log.xaiReportId == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => FutureBuilder<XaiReportInfo>(
        future: _api.getReport(log.xaiReportId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            );
          }
          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('리포트'),
              content: Text('불러오기에 실패했습니다: ${snapshot.error}'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
              ],
            );
          }
          final report = snapshot.data!;
          return AlertDialog(
            title: Text('${report.displayTicker} · ${report.signal}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${report.date} · ${report.price}'),
                  const Divider(),
                  Text(report.report),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('퀀트봇')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('불러오기에 실패했습니다: $_errorMessage'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  Text('현재 포지션', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildPositions(),
                  const SizedBox(height: 20),
                  Text('전략 수익 곡선', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildEquityChart(),
                  const SizedBox(height: 20),
                  Text('매매 로그', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildTradeLogFilter(),
                  const SizedBox(height: 8),
                  _buildTradeLog(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '누적 수익률',
            value: '${overview.cumulativeReturnPercent >= 0 ? '+' : ''}${overview.cumulativeReturnPercent.toStringAsFixed(2)}%',
            color: overview.cumulativeReturnPercent >= 0 ? Colors.blue : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: '총자산',
            value: '${_numberFormat.format(overview.lastTotalAsset)}원',
          ),
        ),
      ],
    );
  }

  Widget _buildPositions() {
    if (_positions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('보유 중인 포지션이 없습니다.'),
      );
    }
    return GlassCard(
      child: Column(
        children: _positions
            .map(
              (p) => ListTile(
                title: Text(p.displayTicker),
                subtitle: Text('수량 ${p.positionQty} · 평균단가 ${_numberFormat.format(p.avgPrice)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_numberFormat.format(p.marketPrice)}원'),
                    Text(
                      '${p.pnl >= 0 ? '+' : ''}${_numberFormat.format(p.pnl)} (${(p.pnlRate * 100).toStringAsFixed(2)}%)',
                      style: TextStyle(color: p.pnl >= 0 ? Colors.blue : Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEquityChart() {
    if (_assets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('자산 추이 데이터가 없습니다.'),
      );
    }
    final spots = <FlSpot>[
      for (var i = 0; i < _assets.length; i++) FlSpot(i.toDouble(), _assets[i].totalAsset),
    ];
    return SizedBox(
      height: 220,
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

  Widget _buildTradeLogFilter() {
    final dates = _logs.map((l) => l.fillDate).toSet().toList()..sort((a, b) => b.compareTo(a));
    return DropdownButtonFormField<String?>(
      initialValue: _selectedDate,
      decoration: const InputDecoration(
        labelText: '날짜 필터',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('전체 날짜')),
        ...dates.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
      ],
      onChanged: (value) => setState(() => _selectedDate = value),
    );
  }

  Widget _buildTradeLog() {
    final filtered = _selectedDate == null
        ? _logs
        : _logs.where((l) => l.fillDate == _selectedDate).toList();
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('매매 로그가 없습니다.'),
      );
    }
    return Column(
      children: filtered
          .map(
            (log) => GlassCard(
              child: ListTile(
                title: Text('${log.displayTicker} · ${log.isBuy ? '매수' : '매도'}'),
                subtitle: Text(
                  '${log.fillDate} · 가격 ${_numberFormat.format(log.fillPrice)} · 수량 ${log.qty}',
                ),
                trailing: log.xaiReportId != null
                    ? TextButton(
                        onPressed: () => _showReport(log),
                        child: const Text('리포트 보기'),
                      )
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
