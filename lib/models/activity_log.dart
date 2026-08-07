class ActivityLogItem {
  ActivityLogItem({
    required this.id,
    required this.activityType,
    required this.message,
    required this.createdAt,
  });

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem(
      id: json['id'] as int? ?? 0,
      activityType: json['activityType'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final int id;
  final String activityType;
  final String message;
  final String createdAt;
}
