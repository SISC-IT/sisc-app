import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/admin_feedback_api.dart';
import '../../core/api_client.dart';
import '../../models/feedback.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final _api = AdminFeedbackApi(ApiClient.instance);
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  final List<FeedbackItem> _items = [];
  int _page = 0;
  bool _loading = true;
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
      final result = await _api.getFeedbacks(page: 0);
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
    if (_last) return;
    try {
      final nextPage = _page + 1;
      final result = await _api.getFeedbacks(page: nextPage);
      setState(() {
        _items.addAll(result.content);
        _page = nextPage;
        _last = result.last;
      });
    } catch (_) {
      // 무시, 다시 스크롤 시 재시도됨
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('피드백')),
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
                  Padding(padding: EdgeInsets.all(24), child: Text('접수된 피드백이 없습니다.')),
                ],
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                    _loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item.content),
                      subtitle: Text(
                        '익명 · ${_dateFormat.format(DateTime.tryParse(item.createdDate) ?? DateTime.now())}',
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
