class UserBetInfo {
  UserBetInfo({
    required this.userBetId,
    required this.betRoundId,
    required this.roundTitle,
    required this.symbol,
    required this.option,
    required this.isFree,
    required this.stakePoints,
    required this.betStatus,
    required this.isCorrect,
    required this.earnedPoints,
    required this.previousClosePrice,
    required this.settleClosePrice,
    required this.upBetCount,
    required this.downBetCount,
  });

  factory UserBetInfo.fromJson(Map<String, dynamic> json) {
    return UserBetInfo(
      userBetId: json['userBetId'] as String,
      betRoundId: json['betRoundId'] as String,
      roundTitle: json['roundTitle'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      option: json['option'] as String? ?? 'RISE',
      isFree: json['isFree'] as bool? ?? true,
      stakePoints: json['stakePoints'] as int?,
      betStatus: json['betStatus'] as String? ?? 'ACTIVE',
      isCorrect: json['isCorrect'] as bool?,
      earnedPoints: json['earnedPoints'] as int?,
      previousClosePrice: (json['previousClosePrice'] as num?)?.toDouble(),
      settleClosePrice: (json['settleClosePrice'] as num?)?.toDouble(),
      upBetCount: json['upBetCount'] as int? ?? 0,
      downBetCount: json['downBetCount'] as int? ?? 0,
    );
  }

  final String userBetId;
  final String betRoundId;
  final String roundTitle;
  final String symbol;
  final String option;
  final bool isFree;
  final int? stakePoints;
  final String betStatus;
  final bool? isCorrect;
  final int? earnedPoints;
  final double? previousClosePrice;
  final double? settleClosePrice;
  final int upBetCount;
  final int downBetCount;

  bool get isSettled => isCorrect != null;
}
