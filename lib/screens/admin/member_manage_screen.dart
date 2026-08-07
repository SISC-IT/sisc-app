import 'package:flutter/material.dart';

import '../../api/admin_user_api.dart';
import '../../core/api_client.dart';
import '../../models/admin_user.dart';

class MemberManageScreen extends StatefulWidget {
  const MemberManageScreen({super.key});

  @override
  State<MemberManageScreen> createState() => _MemberManageScreenState();
}

class _MemberManageScreenState extends State<MemberManageScreen> {
  final _api = AdminUserApi(ApiClient.instance);
  final _searchController = TextEditingController();

  String? _roleFilter;
  String? _statusFilter;
  bool _loading = true;
  String? _errorMessage;
  List<AdminUserInfo> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final users = await _api.getUsers(
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        role: _roleFilter,
        status: _statusFilter,
      );
      setState(() => _users = users);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(AdminUserInfo user) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${user.name} 권한 변경'),
        children: AdminUserInfo.roleLabels.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(e.key),
                  child: Text(e.value),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await _api.updateRole(user.id, selected);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _changeStatus(AdminUserInfo user) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${user.name} 상태 변경'),
        children: AdminUserInfo.statusLabels.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(e.key),
                  child: Text(e.value),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await _api.updateStatus(user.id, selected);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _changeGrade(AdminUserInfo user) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${user.name} 신분 변경'),
        children: AdminUserInfo.gradeLabels.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(e.key),
                  child: Text(e.value),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await _api.updateGrade(user.id, selected);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteUser(AdminUserInfo user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('강제 탈퇴'),
        content: Text('${user.name}(${user.studentId})님을 강제 탈퇴시키겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteUser(user.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원 관리')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '이름/학번/이메일 검색',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _roleFilter,
                        decoration: const InputDecoration(labelText: '권한', isDense: true),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('전체')),
                          ...AdminUserInfo.roleLabels.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                        ],
                        onChanged: (v) {
                          setState(() => _roleFilter = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: '상태', isDense: true),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('전체')),
                          ...AdminUserInfo.statusLabels.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                        ],
                        onChanged: (v) {
                          setState(() => _statusFilter = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text('불러오기에 실패했습니다: $_errorMessage'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          title: Text('${user.name} (${user.studentId})'),
                          subtitle: Text(
                            '${user.roleLabel} · ${user.statusLabel} · ${user.gradeLabel}\n${user.teamName ?? ''} · ${user.point}P',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'role') _changeRole(user);
                              if (value == 'status') _changeStatus(user);
                              if (value == 'grade') _changeGrade(user);
                              if (value == 'delete') _deleteUser(user);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'role', child: Text('권한 변경')),
                              PopupMenuItem(value: 'status', child: Text('상태 변경')),
                              PopupMenuItem(value: 'grade', child: Text('신분 변경')),
                              PopupMenuItem(value: 'delete', child: Text('강제 탈퇴')),
                            ],
                          ),
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
