import 'package:flutter/material.dart';

import '../../widgets/glass_bottom_nav_bar.dart';
import '../../widgets/glass_card.dart';
import '../backtest/backtest_builder_screen.dart';
import '../betting/betting_screen.dart';
import '../quantbot/quant_bot_screen.dart';

class TradingTab extends StatelessWidget {
  const TradingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('트레이딩')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + glassBottomBarClearance(context)),
        children: [
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('퀀트봇'),
                  subtitle: const Text('자동매매 봇 현황'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuantBotScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.trending_up),
                  title: const Text('주식베팅'),
                  subtitle: const Text('일간/주간 상승·하락 예측'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BettingScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_graph),
                  title: const Text('백테스팅'),
                  subtitle: const Text('전략 조건 빌더 & 시뮬레이션'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BacktestBuilderScreen()),
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
