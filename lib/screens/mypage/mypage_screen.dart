import 'package:flutter/material.dart';

import '../../api/user_api.dart';
import '../../core/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../widgets/glass_card.dart';
import '../admin/admin_home_screen.dart';
import '../assetmanagement/asset_management_screen.dart';
import 'activity_log_screen.dart';
import 'edit_profile_screen.dart';
import 'feedback_write_screen.dart';
import 'point_history_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key, required this.authState});

  final AuthState authState;

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final _userApi = UserApi(ApiClient.instance);
  bool _withdrawing = false;

  Future<void> _confirmWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('탈퇴', style: TextStyle(color: context.appColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _withdrawing = true);
    try {
      await _userApi.withdraw();
      widget.authState.markLoggedOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authState.userInfo;
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + glassBottomBarClearance(context)),
        children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name.substring(0, 1) : '?',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '-',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(user?.roleLabel ?? '-'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: context.appColors.pointValue, size: 18),
                      const SizedBox(width: 4),
                      Text('${user?.point ?? 0} P', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('개인정보 수정하기'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(authState: widget.authState),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('내 활동'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.paid),
                  title: const Text('포인트 내역'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PointHistoryScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('피드백 작성하기'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FeedbackWriteScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('자산운용', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('자산운용팀 계좌 조회'),
              subtitle: const Text('자산운용팀 전용'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AssetManagementScreen()),
              ),
            ),
          ),
          if (user?.isAdmin ?? false) ...[
            const SizedBox(height: 24),
            Text('관리자', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('관리자 콘솔'),
                subtitle: const Text('회원승인·엑셀업로드·출석관리·대시보드'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
            onPressed: () => widget.authState.logout(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _withdrawing ? null : _confirmWithdraw,
            style: TextButton.styleFrom(foregroundColor: context.appColors.destructive),
            child: _withdrawing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('회원 탈퇴'),
          ),
        ],
      ),
    );
  }
}
