import 'package:flutter/material.dart';

import '../../api/asset_management_api.dart';
import '../../core/api_client.dart';
import '../../models/asset_management.dart';
import '../../widgets/glass_card.dart';

double? _parseNumber(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.trim().replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (normalized.isEmpty || normalized == '-' || normalized == '.') return null;
  return double.tryParse(normalized);
}

String _formatWon(String? value) {
  final n = _parseNumber(value);
  if (n == null) return value ?? '-';
  return '${n.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원';
}

String _formatRate(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  if (value.contains('%')) return value;
  final n = _parseNumber(value);
  if (n == null) return value;
  return '${n.toStringAsFixed(2)}%';
}

String _formatQuantity(String? value) {
  final n = _parseNumber(value);
  if (n == null) return value ?? '-';
  return n.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
}

Color _tone(String? value) {
  final n = _parseNumber(value);
  if (n == null || n == 0) return Colors.grey.shade400;
  return n > 0 ? Colors.blue : Colors.red;
}

class AssetManagementScreen extends StatefulWidget {
  const AssetManagementScreen({super.key});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  final _api = AssetManagementApi(ApiClient.instance);

  bool _checkingAccess = true;
  bool _hasAccess = false;
  bool _loading = false;
  String? _errorMessage;

  DateTime _date = DateTime.now();
  String _exchangeType = 'KRX';

  List<AccountBalanceInfo> _accounts = [];
  DailyBalanceInfo? _dailyBalance;
  AccountEvaluationInfo? _evaluation;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final access = await _api.checkAccess();
    setState(() {
      _hasAccess = access;
      _checkingAccess = false;
    });
    if (access) await _load();
  }

  String get _queryDate =>
      '${_date.year}${_date.month.toString().padLeft(2, '0')}${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _api.getAccounts(),
        _api.getDailyBalance(_queryDate),
        _api.getEvaluation(_exchangeType),
      ]);
      setState(() {
        _accounts = results[0] as List<AccountBalanceInfo>;
        _dailyBalance = results[1] as DailyBalanceInfo;
        _evaluation = results[2] as AccountEvaluationInfo;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자산관리')),
      body: _checkingAccess
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('자산운용팀 계좌 조회 권한이 없습니다.', textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _exchangeType,
                        items: const [
                          DropdownMenuItem(value: 'KRX', child: Text('KRX')),
                          DropdownMenuItem(value: 'NXT', child: Text('NXT')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _exchangeType = v);
                          _load();
                        },
                      ),
                      IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '조회 계좌 ${_accounts.length}개'
                    '${_accounts.isNotEmpty ? ' · ${_accounts.map((a) => a.maskedAccountNumber).join(', ')}' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('불러오기에 실패했습니다: $_errorMessage'),
                    )
                  else ...[
                    _buildMetricGrid(),
                    const SizedBox(height: 24),
                    Text('일별 잔고 수익률', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildDailyTable(),
                    const SizedBox(height: 24),
                    Text('계좌 평가 현황', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildEvaluationTable(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMetricGrid() {
    final evaluation = _evaluation;
    final daily = _dailyBalance;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _MetricCard(
          label: '예탁자산평가액',
          value: _formatWon(evaluation?.assetEvaluationAmount),
          subValue: '예수금 ${_formatWon(evaluation?.deposit)}',
        ),
        _MetricCard(
          label: '누적 수익률',
          value: _formatRate(evaluation?.accumulatedProfitRate),
          subValue: _formatWon(evaluation?.accumulatedProfitLoss),
          color: _tone(evaluation?.accumulatedProfitRate),
        ),
        _MetricCard(
          label: '일별 평가손익',
          value: _formatWon(daily?.totalEvaluationProfit),
          subValue: _formatRate(daily?.totalProfitRate),
          color: _tone(daily?.totalEvaluationProfit),
        ),
        _MetricCard(
          label: '총 평가금액',
          value: _formatWon(daily?.totalEvaluationAmount),
          subValue: '매입 ${_formatWon(daily?.totalBuyAmount)}',
        ),
      ],
    );
  }

  Widget _buildDailyTable() {
    final stocks = _dailyBalance?.dailyBalanceRate ?? [];
    if (stocks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('표시할 잔고 데이터가 없습니다.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('종목')),
          DataColumn(label: Text('수량')),
          DataColumn(label: Text('평가금액')),
          DataColumn(label: Text('손익률')),
        ],
        rows: stocks
            .map(
              (s) => DataRow(
                cells: [
                  DataCell(Text(s.stockName)),
                  DataCell(Text(_formatQuantity(s.remainderQuantity))),
                  DataCell(Text(_formatWon(s.evaluationAmount))),
                  DataCell(Text(_formatRate(s.profitRate), style: TextStyle(color: _tone(s.profitRate)))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEvaluationTable() {
    final stocks = _evaluation?.stockEvaluations ?? [];
    if (stocks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('표시할 평가 데이터가 없습니다.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('종목')),
          DataColumn(label: Text('보유')),
          DataColumn(label: Text('평균단가')),
          DataColumn(label: Text('현재가')),
          DataColumn(label: Text('평가금액')),
          DataColumn(label: Text('손익')),
        ],
        rows: stocks
            .map(
              (s) => DataRow(
                cells: [
                  DataCell(Text(s.stockName)),
                  DataCell(Text(_formatQuantity(s.remainingQuantity))),
                  DataCell(Text(_formatWon(s.averagePrice))),
                  DataCell(Text(_formatWon(s.currentPrice))),
                  DataCell(Text(_formatWon(s.evaluationAmount))),
                  DataCell(
                    Text(
                      '${_formatWon(s.profitLossAmount)} (${_formatRate(s.profitLossRate)})',
                      style: TextStyle(color: _tone(s.profitLossAmount)),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.subValue, this.color});

  final String label;
  final String value;
  final String? subValue;
  final Color? color;

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
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
              overflow: TextOverflow.ellipsis,
            ),
            if (subValue != null)
              Text(subValue!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
