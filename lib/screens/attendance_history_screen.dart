import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/attendance_api.dart';
import '../core/api_client.dart';
import '../models/attendance.dart';
import '../state/auth_state.dart';
import '../widgets/glass_bottom_nav_bar.dart';
import 'admin/attendance/attendance_admin_screen.dart';
import 'qr_scan_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key, required this.authState});

  final AuthState authState;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _attendanceApi = AttendanceApi(ApiClient.instance);
  final _dateFormat = DateFormat('MM.dd (E)', 'ko_KR');
  final _timeFormat = DateFormat('HH:mm');

  late Future<List<AttendanceRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AttendanceRecord>> _load() => _attendanceApi.getMyAttendances();

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  static const _statusLabels = {
    'PENDING': '대기',
    'PRESENT': '출석',
    'LATE': '지각',
    'ABSENT': '결석',
    'EXCUSED': '공결',
  };

  static const _statusColors = {
    'PENDING': Colors.grey,
    'PRESENT': Colors.blue,
    'LATE': Colors.orange,
    'ABSENT': Colors.red,
    'EXCUSED': Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final user = widget.authState.userInfo;
    return Scaffold(
      appBar: AppBar(title: const Text('출석체크')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('QR 출석'),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrScanScreen()),
                    ),
                  ),
                ),
                if (user?.canManageAttendance ?? false) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('출석 관리(담당자)'),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AttendanceAdminScreen()),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<AttendanceRecord>>(
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
                  final records = snapshot.data ?? [];
                  if (records.isEmpty) {
                    return ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('출석 기록이 없습니다.'),
                        ),
                      ],
                    );
                  }

                  final sorted = [...records]..sort((a, b) {
                    final at = a.roundTimestamp;
                    final bt = b.roundTimestamp;
                    if (at == null || bt == null) return 0;
                    return at.compareTo(bt);
                  });

                  return ListView.separated(
                    padding: EdgeInsets.only(bottom: glassBottomBarClearance(context)),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = sorted[index];
                      final ts = record.roundTimestamp;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            record.roundName.isNotEmpty
                                ? record.roundName.substring(0, 1)
                                : '?',
                          ),
                        ),
                        title: Text('${record.normalizedSessionTitle} · ${record.roundName}'),
                        subtitle: Text(
                          '${ts != null ? _dateFormat.format(ts) : '-'} '
                          '${ts != null ? _timeFormat.format(ts) : ''}\n'
                          '${record.roundLocation}',
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            _statusLabels[record.attendanceStatus] ?? record.attendanceStatus,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _statusColors[record.attendanceStatus] ?? Colors.grey,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
