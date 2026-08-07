class AdminUserInfo {
  AdminUserInfo({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.point,
    required this.grade,
    required this.role,
    required this.status,
    required this.generation,
    required this.college,
    required this.department,
    required this.teamName,
  });

  factory AdminUserInfo.fromJson(Map<String, dynamic> json) {
    return AdminUserInfo(
      id: json['id'] as String,
      studentId: json['studentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      point: (json['point'] as num?)?.toInt() ?? 0,
      grade: json['grade'] as String? ?? 'NEW_MEMBER',
      role: json['role'] as String? ?? 'TEAM_MEMBER',
      status: json['status'] as String? ?? 'ACTIVE',
      generation: json['generation'] as int?,
      college: json['college'] as String?,
      department: json['department'] as String?,
      teamName: json['teamName'] as String?,
    );
  }

  final String id;
  final String studentId;
  final String name;
  final String email;
  final String? phoneNumber;
  final int point;
  final String grade;
  final String role;
  final String status;
  final int? generation;
  final String? college;
  final String? department;
  final String? teamName;

  static const roleLabels = {
    'SYSTEM_ADMIN': '시스템관리자',
    'PRESIDENT': '회장',
    'VICE_PRESIDENT': '부회장',
    'TEAM_LEADER': '팀장',
    'TEAM_MEMBER': '부원',
    'PENDING_MEMBER': '대기회원',
  };

  static const statusLabels = {'ACTIVE': '활동 중', 'INACTIVE': '활동 중지', 'OUT': '탈퇴'};

  static const gradeLabels = {
    'NEW_MEMBER': '신입부원',
    'ASSOCIATE_MEMBER': '준회원',
    'REGULAR_MEMBER': '정회원',
  };

  String get roleLabel => roleLabels[role] ?? role;
  String get statusLabel => statusLabels[status] ?? status;
  String get gradeLabel => gradeLabels[grade] ?? grade;
}
