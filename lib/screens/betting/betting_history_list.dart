import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/betting_api.dart';
import '../../core/api_client.dart';
import '../../models/user_bet.dart';

class BettingHistoryTabs extends StatefulWidget {
  const BettingHistoryTabs({super.key});

  @override
  State<BettingHistoryTabs> createState() => _BettingHistoryTabsState();
}

class _BettingHistoryTabsState extends State<BettingHistoryTabs> {
  final _bettingApi = BettingApi(ApiClient.instance);
  String _scope = 'DAILY';
  late Future<List<UserBetInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserBetInfo>> _load() async {
    final all = await _bettingApi.getMyBetHistory();
    return all.where((b) => b.roundTitle.contains(_scope)).toList();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'DAILY', label: Text('일간')),
              ButtonSegment(value: 'WEEKLY', label: Text('주간')),
            ],
            selected: {_scope},
            onSelectionChanged: (selection) {
              setState(() => _scope = selection.first);
              _refresh();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<UserBetInfo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('불러오기에 실패했습니다: ${snapshot.error}'),
                      ),
                    ],
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('베팅 이력이 없습니다.'),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _HistoryTile(bet: items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.bet});

  final UserBetInfo bet;

  static final _numberFormat = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final optionLabel = bet.option == 'RISE' ? '상승 ↑' : '하락 ↓';
    final change = (bet.previousClosePrice != null && bet.settleClosePrice != null)
        ? (bet.settleClosePrice! - bet.previousClosePrice!) / bet.previousClosePrice! * 100
        : null;

    Widget resultIcon;
    if (!bet.isSettled) {
      resultIcon = const Icon(Icons.hourglass_empty, color: Colors.grey);
    } else if (bet.isCorrect == true) {
      resultIcon = const Icon(Icons.check_circle, color: Colors.green);
    } else {
      resultIcon = const Icon(Icons.cancel, color: Colors.red);
    }

    return ListTile(
      leading: resultIcon,
      title: Text('${bet.roundTitle} · $optionLabel'),
      subtitle: Text(
        '종가 ${bet.previousClosePrice ?? '-'} → 정산 ${bet.settleClosePrice ?? '진행중'}'
        '${change != null ? ' (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%)' : ''}\n'
        '상승 ${bet.upBetCount}명 · 하락 ${bet.downBetCount}명',
      ),
      isThreeLine: true,
      trailing: bet.earnedPoints != null
          ? Text(
              '${bet.earnedPoints! >= 0 ? '+' : ''}${_numberFormat.format(bet.earnedPoints)} P',
              style: TextStyle(
                color: bet.earnedPoints! >= 0 ? Colors.blue : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
