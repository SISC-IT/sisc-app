import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/point_api.dart';
import '../../core/api_client.dart';
import '../../models/point_history.dart';
import '../../theme/app_colors.dart';

class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  final _pointApi = PointApi(ApiClient.instance);
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  final List<PointHistoryItem> _items = [];
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _last = true;
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
      final result = await _pointApi.getHistory(pageNumber: 0);
      setState(() {
        _items
          ..clear()
          ..addAll(result.content);
        _page = 0;
        _last = result.last;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _last) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _pointApi.getHistory(pageNumber: nextPage);
      setState(() {
        _items.addAll(result.content);
        _page = nextPage;
        _last = result.last;
      });
    } catch (_) {
      // 다음 페이지 로드 실패는 조용히 무시하고 재시도 가능하게 둔다.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('포인트 내역')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('불러오기에 실패했습니다: $_errorMessage'),
                  ),
                ],
              )
            : _items.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('포인트 내역이 없습니다.'),
                  ),
                ],
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                    _loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: _items.length + (_last ? 0 : 1),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _items[index];
                    final positive = item.amount >= 0;
                    return ListTile(
                      title: Text(item.reasonLabel),
                      subtitle: Text(_dateFormat.format(DateTime.tryParse(item.createdDate) ?? DateTime.now())),
                      trailing: Text(
                        '${positive ? '+' : ''}${item.amount} P',
                        style: TextStyle(
                          color: positive ? context.appColors.marketRise : context.appColors.marketFall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
