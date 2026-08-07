class BetRoundInfo {
  BetRoundInfo({
    required this.betRoundId,
    required this.title,
    required this.symbol,
    required this.previousClosePrice,
    required this.openAt,
    required this.lockAt,
    required this.upBetCount,
    required this.downBetCount,
    required this.upTotalPoints,
    required this.downTotalPoints,
  });

  factory BetRoundInfo.fromJson(Map<String, dynamic> json) {
    return BetRoundInfo(
      betRoundId: json['betRoundId'] as String,
      title: json['title'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      previousClosePrice: (json['previousClosePrice'] as num?)?.toDouble() ?? 0,
      openAt: json['openAt'] as String?,
      lockAt: json['lockAt'] as String?,
      upBetCount: json['upBetCount'] as int? ?? 0,
      downBetCount: json['downBetCount'] as int? ?? 0,
      upTotalPoints: json['upTotalPoints'] as int? ?? 0,
      downTotalPoints: json['downTotalPoints'] as int? ?? 0,
    );
  }

  final String betRoundId;
  final String title;
  final String symbol;
  final double previousClosePrice;
  final String? openAt;
  final String? lockAt;
  final int upBetCount;
  final int downBetCount;
  final int upTotalPoints;
  final int downTotalPoints;
}
