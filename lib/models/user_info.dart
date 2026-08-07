class UserInfoResponse {
  UserInfoResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.point,
    required this.role,
    required this.teamName,
    required this.status,
  });

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    return UserInfoResponse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      point: json['point'] as int? ?? 0,
      role: json['role'] as String? ?? 'PENDING_MEMBER',
      teamName: json['teamName'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final int point;
  final String role;
  final String? teamName;
  final String status;

  static const _roleLabels = {
    'SYSTEM_ADMIN': '관리자',
    'PRESIDENT': '회장',
    'VICE_PRESIDENT': '부회장',
    'TEAM_LEADER': '팀장',
    'TEAM_MEMBER': '일반',
    'PENDING_MEMBER': '대기회원',
  };

  String get roleLabel => _roleLabels[role] ?? role;

  static const _adminRoles = {'SYSTEM_ADMIN', 'PRESIDENT', 'VICE_PRESIDENT'};

  bool get isAdmin => _adminRoles.contains(role);

  static const _attendanceManageRoles = {
    'SYSTEM_ADMIN',
    'PRESIDENT',
    'VICE_PRESIDENT',
    'TEAM_LEADER',
  };

  /// 웹 Sidebar.jsx의 ATTENDANCE_MANAGE_VISIBLE_ROLES와 동일: 팀장 이상.
  bool get canManageAttendance => _attendanceManageRoles.contains(role);
}
