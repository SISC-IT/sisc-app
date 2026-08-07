class AttendanceSessionInfo {
  AttendanceSessionInfo({
    required this.sessionId,
    required this.title,
    required this.description,
    required this.allowedMinutes,
    required this.status,
    required this.myRole,
    required this.canUpdateSession,
    required this.canCloseSession,
  });

  factory AttendanceSessionInfo.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>?;
    final permissions = json['permissions'] as Map<String, dynamic>?;
    return AttendanceSessionInfo(
      sessionId: json['sessionId'] as String,
      title: session?['title'] as String? ?? '',
      description: session?['description'] as String?,
      allowedMinutes: session?['allowedMinutes'] as int?,
      status: session?['status'] as String? ?? 'OPEN',
      myRole: json['myRole'] as String?,
      canUpdateSession: permissions?['canUpdateSession'] as bool? ?? false,
      canCloseSession: permissions?['canCloseSession'] as bool? ?? false,
    );
  }

  final String sessionId;
  final String title;
  final String? description;
  final int? allowedMinutes;
  final String status;
  final String? myRole;
  final bool canUpdateSession;
  final bool canCloseSession;
}

class AttendanceRoundInfo {
  AttendanceRoundInfo({
    required this.roundId,
    required this.sessionId,
    required this.roundDate,
    required this.startAt,
    required this.closeAt,
    required this.roundStatus,
    required this.roundName,
    required this.locationName,
  });

  factory AttendanceRoundInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceRoundInfo(
      roundId: json['roundId'] as String,
      sessionId: json['sessionId'] as String,
      roundDate: json['roundDate'] as String?,
      startAt: json['startAt'] as String?,
      closeAt: json['closeAt'] as String?,
      roundStatus: json['roundStatus'] as String? ?? 'UPCOMING',
      roundName: json['roundName'] as String? ?? '',
      locationName: json['locationName'] as String?,
    );
  }

  final String roundId;
  final String sessionId;
  final String? roundDate;
  final String? startAt;
  final String? closeAt;
  final String roundStatus;
  final String roundName;
  final String? locationName;
}

class RoundHeader {
  RoundHeader({required this.roundId, required this.roundNumber});

  factory RoundHeader.fromJson(Map<String, dynamic> json) {
    return RoundHeader(
      roundId: json['roundId'] as String,
      roundNumber: json['roundNumber'] as int? ?? 0,
    );
  }

  final String roundId;
  final int roundNumber;
}

class AttendanceStatusEntry {
  AttendanceStatusEntry({required this.roundId, required this.status, required this.attendanceId});

  factory AttendanceStatusEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusEntry(
      roundId: json['roundId'] as String,
      status: json['status'] as String? ?? 'PENDING',
      attendanceId: json['attendanceId'] as String?,
    );
  }

  final String roundId;
  final String status;
  final String? attendanceId;
}

class UserAttendanceRow {
  UserAttendanceRow({
    required this.userId,
    required this.userName,
    required this.studentId,
    required this.role,
    required this.attendances,
  });

  factory UserAttendanceRow.fromJson(Map<String, dynamic> json) {
    final list = json['attendances'] as List<dynamic>? ?? [];
    return UserAttendanceRow(
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? '',
      studentId: json['studentId'] as String?,
      role: json['role'] as String? ?? '일반',
      attendances: list.map((e) => AttendanceStatusEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  final String userId;
  final String userName;
  final String? studentId;
  final String role;
  final List<AttendanceStatusEntry> attendances;

  String statusForRound(String roundId) {
    final entry = attendances.where((a) => a.roundId == roundId);
    return entry.isNotEmpty ? entry.first.status : 'PENDING';
  }
}

class SessionAttendanceTable {
  SessionAttendanceTable({required this.sessionTitle, required this.rounds, required this.userRows});

  factory SessionAttendanceTable.fromJson(Map<String, dynamic> json) {
    final rounds = json['rounds'] as List<dynamic>? ?? [];
    final userRows = json['userRows'] as List<dynamic>? ?? [];
    return SessionAttendanceTable(
      sessionTitle: json['sessionTitle'] as String? ?? '',
      rounds: rounds.map((e) => RoundHeader.fromJson(e as Map<String, dynamic>)).toList(),
      userRows: userRows.map((e) => UserAttendanceRow.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  final String sessionTitle;
  final List<RoundHeader> rounds;
  final List<UserAttendanceRow> userRows;
}

class AvailableSessionUser {
  AvailableSessionUser({
    required this.userId,
    required this.studentId,
    required this.name,
    required this.teamName,
  });

  factory AvailableSessionUser.fromJson(Map<String, dynamic> json) {
    return AvailableSessionUser(
      userId: json['userId'] as String,
      studentId: json['studentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      teamName: json['teamName'] as String?,
    );
  }

  final String userId;
  final String studentId;
  final String name;
  final String? teamName;
}
