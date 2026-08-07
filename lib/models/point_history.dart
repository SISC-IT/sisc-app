class PointHistoryItem {
  PointHistoryItem({
    required this.entryId,
    required this.reason,
    required this.amount,
    required this.createdDate,
  });

  factory PointHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointHistoryItem(
      entryId: json['entryId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      createdDate: json['createdDate'] as String? ?? '',
    );
  }

  final String entryId;
  final String reason;
  final int amount;
  final String createdDate;

  static const _reasonLabels = {
    'ATTENDANCE': '출석',
    'SIGNUP_REWARD': '회원가입',
    'BETTING_STAKE': '베팅 참여',
    'BETTING_REWARD': '베팅 적중',
    'BETTING_REFUND': '베팅 환불',
    'BETTING_CANCEL': '베팅 취소',
    'BETTING_RESIDUAL': '베팅 잔액 정산',
    'SYSTEM_ADJUSTMENT': '관리자 조정',
    'MIGRATION': '데이터 이전',
  };

  String get reasonLabel => _reasonLabels[reason] ?? '기타';
}

class PageResult<T> {
  PageResult({required this.content, required this.totalPages, required this.last});

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final content = (json['content'] as List<dynamic>? ?? [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    return PageResult(
      content: content,
      totalPages: json['totalPages'] as int? ?? 1,
      last: json['last'] as bool? ?? true,
    );
  }

  final List<T> content;
  final int totalPages;
  final bool last;
}
