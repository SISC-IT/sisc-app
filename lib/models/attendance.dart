class AttendanceRecord {
  AttendanceRecord({
    required this.roundId,
    required this.sessionTitle,
    required this.roundName,
    required this.roundLocation,
    required this.roundDate,
    required this.roundStartAt,
    required this.attendanceStatus,
    required this.checkedAt,
    this.note,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      roundId: json['roundId'] as String?,
      sessionTitle: json['sessionTitle'] as String? ?? '',
      roundName: json['roundName'] as String? ?? '',
      roundLocation: json['roundLocation'] as String? ?? '',
      roundDate: json['roundDate'] as String?,
      roundStartAt: json['roundStartAt'] as String?,
      attendanceStatus: json['attendanceStatus'] as String? ?? 'PENDING',
      checkedAt: json['checkedAt'] as String?,
      note: json['note'] as String?,
    );
  }

  final String? roundId;
  final String sessionTitle;
  final String roundName;
  final String roundLocation;
  final String? roundDate;
  final String? roundStartAt;
  final String attendanceStatus;
  final String? checkedAt;
  final String? note;

  String get normalizedSessionTitle =>
      sessionTitle.trim().isEmpty ? '기타' : sessionTitle.trim();

  DateTime? get roundTimestamp =>
      DateTime.tryParse(roundStartAt ?? roundDate ?? checkedAt ?? '');
}
