class PortfolioOverview {
  PortfolioOverview({
    required this.startDate,
    required this.endDate,
    required this.lastTotalAsset,
    required this.initialCapital,
  });

  factory PortfolioOverview.fromJson(Map<String, dynamic> json) {
    return PortfolioOverview(
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      lastTotalAsset: (json['lastTotalAsset'] as num?)?.toDouble() ?? 0,
      initialCapital: (json['initialCapital'] as num?)?.toDouble() ?? 0,
    );
  }

  final String? startDate;
  final String? endDate;
  final double lastTotalAsset;
  final double initialCapital;

  double get cumulativeReturnPercent =>
      initialCapital == 0 ? 0 : (lastTotalAsset / initialCapital - 1) * 100;
}

class AssetPoint {
  AssetPoint({required this.date, required this.totalAsset});

  factory AssetPoint.fromJson(Map<String, dynamic> json) {
    return AssetPoint(
      date: json['date'] as String? ?? '',
      totalAsset: (json['totalAsset'] as num?)?.toDouble() ?? 0,
    );
  }

  final String date;
  final double totalAsset;
}

class PositionInfo {
  PositionInfo({
    required this.ticker,
    required this.displayTicker,
    required this.positionQty,
    required this.avgPrice,
    required this.currentPrice,
    required this.marketPrice,
    required this.pnl,
    required this.pnlRate,
  });

  factory PositionInfo.fromJson(Map<String, dynamic> json) {
    return PositionInfo(
      ticker: json['ticker'] as String? ?? '',
      displayTicker: json['displayTicker'] as String? ?? json['ticker'] as String? ?? '',
      positionQty: json['positionQty'] as int? ?? 0,
      avgPrice: (json['avgPrice'] as num?)?.toDouble() ?? 0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      marketPrice: (json['marketPrice'] as num?)?.toDouble() ?? 0,
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0,
      pnlRate: (json['pnlRate'] as num?)?.toDouble() ?? 0,
    );
  }

  final String ticker;
  final String displayTicker;
  final int positionQty;
  final double avgPrice;
  final double currentPrice;
  final double marketPrice;
  final double pnl;
  final double pnlRate;
}

class TradeLogInfo {
  TradeLogInfo({
    required this.id,
    required this.xaiReportId,
    required this.ticker,
    required this.displayTicker,
    required this.fillDate,
    required this.fillPrice,
    required this.qty,
    required this.side,
    required this.positionQty,
    required this.avgPrice,
    required this.pnlRealized,
  });

  factory TradeLogInfo.fromJson(Map<String, dynamic> json) {
    return TradeLogInfo(
      id: json['id'] as int,
      xaiReportId: json['xaiReportId'] as int?,
      ticker: json['ticker'] as String? ?? '',
      displayTicker: json['displayTicker'] as String? ?? json['ticker'] as String? ?? '',
      fillDate: json['fillDate'] as String? ?? '',
      fillPrice: (json['fillPrice'] as num?)?.toDouble() ?? 0,
      qty: json['qty'] as int? ?? 0,
      side: json['side'] as String? ?? '',
      positionQty: json['positionQty'] as int?,
      avgPrice: (json['avgPrice'] as num?)?.toDouble(),
      pnlRealized: (json['pnlRealized'] as num?)?.toDouble(),
    );
  }

  final int id;
  final int? xaiReportId;
  final String ticker;
  final String displayTicker;
  final String fillDate;
  final double fillPrice;
  final int qty;
  final String side;
  final int? positionQty;
  final double? avgPrice;
  final double? pnlRealized;

  bool get isBuy => side.toUpperCase() == 'BUY';
}

class XaiReportInfo {
  XaiReportInfo({
    required this.ticker,
    required this.displayTicker,
    required this.signal,
    required this.price,
    required this.date,
    required this.report,
  });

  factory XaiReportInfo.fromJson(Map<String, dynamic> json) {
    return XaiReportInfo(
      ticker: json['ticker'] as String? ?? '',
      displayTicker: json['displayTicker'] as String? ?? json['ticker'] as String? ?? '',
      signal: json['signal'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      date: json['date'] as String? ?? '',
      report: json['report'] as String? ?? '',
    );
  }

  final String ticker;
  final String displayTicker;
  final String signal;
  final double price;
  final String date;
  final String report;
}
