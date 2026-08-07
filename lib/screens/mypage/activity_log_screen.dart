import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/user_api.dart';
import '../../core/api_client.dart';
import '../../models/activity_log.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('활동 내역'),
          bottom: const TabBar(tabs: [Tab(text: '게시판'), Tab(text: '출석')]),
        ),
        body: const TabBarView(
          children: [
            _ActivityLogList(kind: _LogKind.board),
            _ActivityLogList(kind: _LogKind.attendance),
          ],
        ),
      ),
    );
  }
}

enum _LogKind { board, attendance }

class _ActivityLogList extends StatefulWidget {
  const _ActivityLogList({required this.kind});
  final _LogKind kind;

  @override
  State<_ActivityLogList> createState() => _ActivityLogListState();
}

class _ActivityLogListState extends State<_ActivityLogList> {
  final _userApi = UserApi(ApiClient.instance);
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  late Future<List<ActivityLogItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ActivityLogItem>> _load() async {
    final result = widget.kind == _LogKind.board
        ? await _userApi.getBoardLogs()
        : await _userApi.getAttendanceLogs();
    return result.content;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ActivityLogItem>>(
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
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('활동 내역이 없습니다.'),
                ),
              ],
            );
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.message),
                subtitle: Text(_dateFormat.format(
                  DateTime.tryParse(log.createdAt) ?? DateTime.now(),
                )),
              );
            },
          );
        },
      ),
    );
  }
}
