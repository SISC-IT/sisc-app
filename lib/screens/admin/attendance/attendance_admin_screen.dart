import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../api/attendance_admin_api.dart';
import '../../../core/api_client.dart';
import '../../../models/attendance_session.dart';
import '../../../widgets/glass_card.dart';
import 'attendance_table_screen.dart';
import 'qr_display_screen.dart';

class AttendanceAdminScreen extends StatefulWidget {
  const AttendanceAdminScreen({super.key});

  @override
  State<AttendanceAdminScreen> createState() => _AttendanceAdminScreenState();
}

class _AttendanceAdminScreenState extends State<AttendanceAdminScreen> {
  final _api = AttendanceAdminApi(ApiClient.instance);
  final _dateFormat = DateFormat('MM.dd HH:mm');

  List<AttendanceSessionInfo> _sessions = [];
  AttendanceSessionInfo? _selectedSession;
  List<AttendanceRoundInfo> _rounds = [];
  bool _loadingSessions = true;
  bool _loadingRounds = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loadingSessions = true;
      _errorMessage = null;
    });
    try {
      final sessions = await _api.getSessions();
      setState(() {
        _sessions = sessions;
        if (_selectedSession != null) {
          final match = sessions.where((s) => s.sessionId == _selectedSession!.sessionId);
          _selectedSession = match.isNotEmpty ? match.first : (sessions.isNotEmpty ? sessions.first : null);
        } else {
          _selectedSession = sessions.isNotEmpty ? sessions.first : null;
        }
      });
      if (_selectedSession != null) await _loadRounds();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _loadRounds() async {
    final session = _selectedSession;
    if (session == null) return;
    setState(() => _loadingRounds = true);
    try {
      final rounds = await _api.getRounds(session.sessionId);
      setState(() => _rounds = rounds);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingRounds = false);
    }
  }

  Future<void> _createSession() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final minutesController = TextEditingController(text: '10');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세션 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: '세션 이름')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: '세션 설명')),
            TextField(
              controller: minutesController,
              decoration: const InputDecoration(labelText: '출석 가능 시간(분)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('생성')),
        ],
      ),
    );
    if (confirmed != true || titleController.text.trim().isEmpty) return;
    try {
      await _api.createSession(
        title: titleController.text.trim(),
        description: descController.text.trim(),
        allowedMinutes: int.tryParse(minutesController.text) ?? 10,
      );
      _loadSessions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteSession() async {
    final session = _selectedSession;
    if (session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세션 삭제'),
        content: Text('"${session.title}" 세션과 모든 회차/출석 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteSession(session.sessionId);
      _selectedSession = null;
      _loadSessions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _createRound() async {
    final session = _selectedSession;
    if (session == null) return;
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    DateTime date = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('회차 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '회차 이름')),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: '장소')),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
                child: Text(
                  '날짜: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: startTime);
                  if (picked != null) setDialogState(() => startTime = picked);
                },
                child: Text('시작 시간: ${startTime.format(context)}'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('추가')),
          ],
        ),
      ),
    );
    if (confirmed != true || nameController.text.trim().isEmpty) return;

    final startAt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
    final closeAt = startAt.add(const Duration(hours: 1));
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T'
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';

    try {
      await _api.createRound(
        sessionId: session.sessionId,
        roundDate:
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        startAt: iso(startAt),
        closeAt: iso(closeAt),
        roundName: nameController.text.trim(),
        locationName: locationController.text.trim(),
      );
      _loadRounds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteRound(AttendanceRoundInfo round) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회차 삭제'),
        content: Text('"${round.roundName}" 회차를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteRound(round.roundId);
      _loadRounds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출석 관리'),
        actions: [
          if (_selectedSession != null)
            IconButton(
              icon: const Icon(Icons.table_chart_outlined),
              tooltip: '출석부',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceTableScreen(session: _selectedSession!),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedSession == null
          ? FloatingActionButton(onPressed: _createSession, child: const Icon(Icons.add))
          : FloatingActionButton(onPressed: _createRound, child: const Icon(Icons.add)),
      body: _loadingSessions
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('불러오기에 실패했습니다: $_errorMessage'))
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AttendanceSessionInfo>(
                          initialValue: _selectedSession,
                          decoration: const InputDecoration(labelText: '세션', border: OutlineInputBorder()),
                          items: _sessions
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.title)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedSession = v);
                            _loadRounds();
                          },
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add_box_outlined), tooltip: '세션 생성', onPressed: _createSession),
                      if (_selectedSession != null)
                        IconButton(icon: const Icon(Icons.delete_outline), tooltip: '세션 삭제', onPressed: _deleteSession),
                    ],
                  ),
                  if (_sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('생성된 세션이 없습니다.'),
                    ),
                  const SizedBox(height: 16),
                  if (_loadingRounds)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_selectedSession != null) ...[
                    Text('회차 목록', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_rounds.isEmpty) const Text('등록된 회차가 없습니다.'),
                    ..._rounds.map(
                      (round) => GlassCard(
                        child: ListTile(
                          title: Text(round.roundName),
                          subtitle: Text(
                            '${round.startAt != null ? _dateFormat.format(DateTime.tryParse(round.startAt!) ?? DateTime.now()) : ''} '
                            '· ${round.locationName ?? ''} · ${round.roundStatus}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'QR 코드',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => QrDisplayScreen(roundId: round.roundId, roundName: round.roundName),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteRound(round),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
