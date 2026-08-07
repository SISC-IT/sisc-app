import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import 'attendance/attendance_admin_screen.dart';
import 'dashboard_screen.dart';
import 'excel_upload_screen.dart';
import 'feedback_screen.dart';
import 'member_approval_screen.dart';
import 'member_manage_screen.dart';
import 'public_pages_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_AdminMenuItem>[
      _AdminMenuItem('가입 승인', Icons.how_to_reg_outlined, (context) => const MemberApprovalScreen()),
      _AdminMenuItem('회원 관리', Icons.people_outline, (context) => const MemberManageScreen()),
      _AdminMenuItem('엑셀 업로드', Icons.upload_file_outlined, (context) => const ExcelUploadScreen()),
      _AdminMenuItem('출석 관리', Icons.event_available_outlined, (context) => const AttendanceAdminScreen()),
      _AdminMenuItem('공개 페이지 관리', Icons.public, (context) => const PublicPagesScreen()),
      _AdminMenuItem('피드백', Icons.feedback_outlined, (context) => const AdminFeedbackScreen()),
      _AdminMenuItem('통계 대시보드', Icons.bar_chart, (context) => const AdminDashboardScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('관리자')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return GlassCard(
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: item.builder),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminMenuItem {
  _AdminMenuItem(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}
