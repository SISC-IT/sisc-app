import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/backtest_api.dart';
import '../../core/api_client.dart';
import '../../models/backtest.dart';
import '../../widgets/glass_card.dart';

class BacktestResultScreen extends StatefulWidget {
  const BacktestResultScreen({super.key, required this.runId, this.initial});

  final int runId;
  final BacktestResult? initial;

  @override
  State<BacktestResultScreen> createState() => _BacktestResultScreenState();
}

class _BacktestResultScreenState extends State<BacktestResultScreen> {
  final _backtestApi = BacktestApi(ApiClient.instance);
  final _numberFormat = NumberFormat('#,##0');

  BacktestResult? _result;
  bool _loading = true;
  bool _polling = false;
  String? _errorMessage;
  bool _showMultiple = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _result = widget.initial;
    if (_result?.run?.isFinal == true && _result?.metrics != null) {
      _loading = false;
    } else {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _polling = true;
    _pollStatus();
  }

  Future<void> _pollStatus() async {
    try {
      final status = await _backtestApi.getStatus(widget.runId);
      if (status.run?.isFinal == true) {
        final detail = await _backtestApi.getRunDetail(widget.runId);
        setState(() {
          _result = detail;
          _loading = false;
          _polling = false;
        });
        return;
      }
      setState(() => _result = status);
      _pollTimer = Timer(const Duration(milliseconds: 1500), _pollStatus);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
        _polling = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 백테스트 결과를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _backtestApi.deleteRun(widget.runId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveToTemplate() async {
    List<TemplateInfo> templates;
    try {
      templates = await _backtestApi.getTemplates();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!mounted) return;
    final newTitleController = TextEditingController();
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('템플릿에 저장'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (templates.isNotEmpty)
                ...templates.map(
                  (t) => ListTile(
                    title: Text(t.title),
                    onTap: () => Navigator.of(context).pop(t.templateId),
                  ),
                ),
              const Divider(),
              TextField(
                controller: newTitleController,
                decoration: const InputDecoration(labelText: '새 템플릿 이름'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  if (newTitleController.text.trim().isEmpty) return;
                  try {
                    final created = await _backtestApi.createTemplate(
                      title: newTitleController.text.trim(),
                    );
                    if (context.mounted) Navigator.of(context).pop(created.templateId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('새로 만들어서 저장'),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    try {
      await _backtestApi.saveRunToTemplate(runId: widget.runId, templateId: selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿에 저장되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = _result?.run;
    final metrics = _result?.metrics;

    return Scaffold(
      appBar: AppBar(
        title: Text(run?.title ?? '백테스트 결과'),
        actions: [
          if (run?.isFinal == true) ...[
            IconButton(icon: const Icon(Icons.bookmark_add_outlined), onPressed: _saveToTemplate),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ],
      ),
      body: _loading || _polling
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('백테스트 실행 중...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(child: Text('불러오기에 실패했습니다: $_errorMessage'))
          : run == null
          ? const Center(child: Text('결과를 찾을 수 없습니다.'))
          : run.status == 'FAILED'
          ? Center(child: Text('백테스트 실행에 실패했습니다.\n${run.errorMessage ?? ''}'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (run.startDate != null && run.endDate != null)
                  Text(
                    '${run.startDate} ~ ${run.endDate}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                if (metrics != null) _buildMetricGrid(metrics, run),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('자산 곡선', style: TextStyle(fontWeight: FontWeight.bold)),
                    ToggleButtons(
                      isSelected: [_showMultiple, !_showMultiple],
                      onPressed: (index) => setState(() => _showMultiple = index == 0),
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 64),
                      children: const [Text('배율'), Text('자산값')],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (metrics != null) _buildChart(metrics, run),
              ],
            ),
    );
  }

  Widget _buildMetricGrid(BacktestMetricsInfo metrics, BacktestRunInfo run) {
    final initialCapital = (run.strategyParams['initialCapital'] as num?)?.toDouble();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _MetricCard(label: '누적 수익률', value: '${metrics.totalReturn.toStringAsFixed(2)}%'),
        _MetricCard(label: '최대 낙폭', value: '${metrics.maxDrawdown.toStringAsFixed(2)}%'),
        _MetricCard(label: '샤프 지수', value: metrics.sharpeRatio.toStringAsFixed(2)),
        _MetricCard(label: '평균 보유일수', value: '${metrics.avgHoldDays.toStringAsFixed(1)}일'),
        _MetricCard(label: '거래 횟수', value: '${metrics.tradesCount}회'),
        _MetricCard(
          label: '초기 자본',
          value: initialCapital != null ? _numberFormat.format(initialCapital) : '-',
        ),
      ],
    );
  }

  Widget _buildChart(BacktestMetricsInfo metrics, BacktestRunInfo run) {
    final curve = metrics.equityCurve;
    if (curve.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('자산 곡선 데이터가 없습니다.'),
      );
    }
    final initialCapital = (run.strategyParams['initialCapital'] as num?)?.toDouble() ?? curve.first;
    final spots = <FlSpot>[
      for (var i = 0; i < curve.length; i++)
        FlSpot(i.toDouble(), _showMultiple ? curve[i] / initialCapital : curve[i]),
    ];
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
