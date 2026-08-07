import 'package:flutter/material.dart';

import '../../api/admin_user_api.dart';
import '../../core/api_client.dart';
import '../../models/admin_user.dart';

class MemberApprovalScreen extends StatefulWidget {
  const MemberApprovalScreen({super.key});

  @override
  State<MemberApprovalScreen> createState() => _MemberApprovalScreenState();
}

class _MemberApprovalScreenState extends State<MemberApprovalScreen> {
  final _api = AdminUserApi(ApiClient.instance);
  late Future<List<AdminUserInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getUsers(role: 'PENDING_MEMBER');
  }

  Future<void> _refresh() async {
    final future = _api.getUsers(role: 'PENDING_MEMBER');
    setState(() => _future = future);
    await future;
  }

  Future<void> _approve(AdminUserInfo user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('승인'),
        content: Text('${user.name}(${user.studentId})님을 승인하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('승인')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.updateRole(user.id, 'TEAM_MEMBER');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reject(AdminUserInfo user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거절'),
        content: Text('${user.name}(${user.studentId})님의 가입을 거절하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('거절', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.updateStatus(user.id, 'OUT');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가입 승인')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminUserInfo>>(
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
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('승인 대기 중인 회원이 없습니다.'),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text('${user.name} (${user.studentId})'),
                  subtitle: Text('${user.email}\n${user.department ?? ''} · ${user.phoneNumber ?? ''}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                        onPressed: () => _approve(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        onPressed: () => _reject(user),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
