import 'package:flutter/material.dart';

import '../../../api/attendance_admin_api.dart';
import '../../../core/api_client.dart';
import '../../../models/attendance_session.dart';

class AttendanceTableScreen extends StatefulWidget {
  const AttendanceTableScreen({super.key, required this.session});

  final AttendanceSessionInfo session;

  @override
  State<AttendanceTableScreen> createState() => _AttendanceTableScreenState();
}

class _AttendanceTableScreenState extends State<AttendanceTableScreen> {
  final _api = AttendanceAdminApi(ApiClient.instance);

  static const _statusLabels = {
    'PENDING': '미정',
    'PRESENT': '출석',
    'LATE': '지각',
    'ABSENT': '결석',
    'EXCUSED': '공결',
  };

  late Future<SessionAttendanceTable> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getAttendanceTable(widget.session.sessionId);
  }

  Future<void> _refresh() async {
    final future = _api.getAttendanceTable(widget.session.sessionId);
    setState(() => _future = future);
    await future;
  }

  Future<void> _changeStatus(String roundId, String userId, String status) async {
    try {
      await _api.updateAttendanceStatus(roundId: roundId, userId: userId, status: status);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _addUsers() async {
    List<AvailableSessionUser> available;
    try {
      available = await _api.getAvailableUsers(widget.session.sessionId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('추가 가능한 회원이 없습니다.')));
      return;
    }
    final selected = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('회원 추가', style: TextStyle(fontWeight: FontWeight.bold))),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        for (final userId in selected) {
                          try {
                            await _api.addUserToSession(widget.session.sessionId, userId);
                          } catch (_) {
                            // 일부 실패는 무시하고 계속 진행한다.
                          }
                        }
                        _refresh();
                      },
                      child: Text('추가하기 (${selected.length})'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final user = available[index];
                    final checked = selected.contains(user.userId);
                    return CheckboxListTile(
                      value: checked,
                      title: Text('${user.name} (${user.studentId})'),
                      subtitle: Text(user.teamName ?? ''),
                      onChanged: (v) {
                        setSheetState(() {
                          if (v == true) {
                            selected.add(user.userId);
                          } else {
                            selected.remove(user.userId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 회원 추가'),
        content: const Text('활동 중인 전체 회원을 이 세션에 추가하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('추가')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.addAllUsers(widget.session.sessionId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출석부'),
        actions: [
          IconButton(icon: const Icon(Icons.group_add_outlined), tooltip: '회원 추가', onPressed: _addUsers),
          IconButton(icon: const Icon(Icons.groups_outlined), tooltip: '전체 추가', onPressed: _addAll),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<SessionAttendanceTable>(
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
            final table = snapshot.data!;
            if (table.userRows.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('세션에 참여 중인 회원이 없습니다.'),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('이름')),
                  const DataColumn(label: Text('역할')),
                  ...table.rounds.map((r) => DataColumn(label: Text('${r.roundNumber}회'))),
                ],
                rows: table.userRows
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(row.userName)),
                          DataCell(Text(row.role)),
                          ...table.rounds.map((r) {
                            final status = row.statusForRound(r.roundId);
                            return DataCell(
                              DropdownButton<String>(
                                value: status,
                                underline: const SizedBox.shrink(),
                                items: _statusLabels.entries
                                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _changeStatus(r.roundId, row.userId, v);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
