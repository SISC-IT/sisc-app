import 'package:flutter/material.dart';

import 'betting_card.dart';
import 'betting_history_list.dart';

class BettingScreen extends StatelessWidget {
  const BettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('주식베팅'),
          bottom: const TabBar(tabs: [Tab(text: '진행률'), Tab(text: '이력')]),
        ),
        body: const TabBarView(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  BettingCard(scope: 'DAILY', title: '일간 베팅'),
                  SizedBox(height: 16),
                  BettingCard(scope: 'WEEKLY', title: '주간 베팅'),
                ],
              ),
            ),
            BettingHistoryTabs(),
          ],
        ),
      ),
    );
  }
}
