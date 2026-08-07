class SummaryInfo {
  SummaryInfo({required this.count, required this.percentageComparedToLastWeek});

  factory SummaryInfo.fromJson(Map<String, dynamic> json) {
    return SummaryInfo(
      count: json['count'] as int? ?? 0,
      percentageComparedToLastWeek: (json['percentageComparedToLastWeek'] as num?)?.toDouble() ?? 0,
    );
  }

  final int count;
  final double percentageComparedToLastWeek;
}

class VisitorTrendPoint {
  VisitorTrendPoint({required this.date, required this.visitorCount});

  factory VisitorTrendPoint.fromJson(Map<String, dynamic> json) {
    return VisitorTrendPoint(
      date: json['date'] as String? ?? '',
      visitorCount: json['visitorCount'] as int? ?? 0,
    );
  }

  final String date;
  final int visitorCount;
}

class BoardActivityPoint {
  BoardActivityPoint({required this.boardName, required this.activityCount});

  factory BoardActivityPoint.fromJson(Map<String, dynamic> json) {
    return BoardActivityPoint(
      boardName: json['boardName'] as String? ?? '',
      activityCount: json['activityCount'] as int? ?? 0,
    );
  }

  final String boardName;
  final int activityCount;
}

class RoleDistributionPoint {
  RoleDistributionPoint({required this.roleName, required this.count});

  factory RoleDistributionPoint.fromJson(Map<String, dynamic> json) {
    return RoleDistributionPoint(
      roleName: json['roleName'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  final String roleName;
  final int count;
}

class AdminActivityLogItem {
  AdminActivityLogItem({
    required this.id,
    required this.username,
    required this.message,
    required this.createdAt,
  });

  factory AdminActivityLogItem.fromJson(Map<String, dynamic> json) {
    return AdminActivityLogItem(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final int id;
  final String username;
  final String message;
  final String createdAt;
}
