import 'package:flutter/material.dart';

import '../../api/betting_api.dart';
import '../../core/api_client.dart';
import '../../models/bet_round.dart';
import '../../models/user_bet.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class BettingCard extends StatefulWidget {
  const BettingCard({super.key, required this.scope, required this.title});

  final String scope;
  final String title;

  @override
  State<BettingCard> createState() => _BettingCardState();
}

class _BettingCardState extends State<BettingCard> {
  final _bettingApi = BettingApi(ApiClient.instance);

  BetRoundInfo? _round;
  UserBetInfo? _myBet;
  bool _loading = true;
  bool _acting = false;
  String? _errorMessage;

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
      final round = await _bettingApi.getActiveRound(widget.scope);
      UserBetInfo? myBet;
      if (round != null) {
        final history = await _bettingApi.getMyBetHistory();
        final matches = history.where(
          (b) => b.roundTitle.contains(widget.scope) && b.betRoundId == round.betRoundId,
        );
        myBet = matches.isNotEmpty ? matches.first : null;
      }
      setState(() {
        _round = round;
        _myBet = myBet;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bet(String option) async {
    if (_myBet != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 베팅하셨습니다.')));
      return;
    }
    final label = option == 'RISE' ? '상승' : '하락';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('베팅 확인'),
        content: Text('$label에 베팅하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('확인')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      await _bettingApi.placeBet(roundId: _round!.betRoundId, option: option);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('베팅이 완료되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('베팅 취소'),
        content: const Text('베팅을 취소하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('아니오')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('취소하기')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      await _bettingApi.cancelBet(_myBet!.userBetId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('베팅이 취소되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            : _errorMessage != null
            ? Text('불러오기에 실패했습니다: $_errorMessage')
            : _round == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('진행 중인 라운드가 없습니다.'),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_round!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('종목: ${_round!.symbol}'),
                      const SizedBox(width: 16),
                      Text('종가: ${_round!.previousClosePrice}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _BetOptionButton(
                          label: '상승 ↑',
                          points: _round!.upTotalPoints,
                          count: _round!.upBetCount,
                          color: context.appColors.marketRise,
                          selected: _myBet?.option == 'RISE',
                          onPressed: _acting ? null : () => _bet('RISE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BetOptionButton(
                          label: '하락 ↓',
                          points: _round!.downTotalPoints,
                          count: _round!.downBetCount,
                          color: context.appColors.marketFall,
                          selected: _myBet?.option == 'FALL',
                          onPressed: _acting ? null : () => _bet('FALL'),
                        ),
                      ),
                    ],
                  ),
                  if (_myBet != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _acting ? null : _cancel,
                        child: const Text('X 취소하기', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _BetOptionButton extends StatelessWidget {
  const _BetOptionButton({
    required this.label,
    required this.points,
    required this.count,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final int points;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: selected ? color.withValues(alpha: 0.15) : null,
        side: BorderSide(color: selected ? color : Colors.grey.shade400),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$points P · $count명', style: const TextStyle(fontSize: 11)),
          if (selected) const Text('✓ 베팅함', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
