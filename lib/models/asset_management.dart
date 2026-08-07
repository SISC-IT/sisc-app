class AccountBalanceInfo {
  AccountBalanceInfo({required this.maskedAccountNumber});

  factory AccountBalanceInfo.fromJson(Map<String, dynamic> json) {
    return AccountBalanceInfo(maskedAccountNumber: json['maskedAccountNumber'] as String? ?? '');
  }

  final String maskedAccountNumber;
}

class DailyStockItem {
  DailyStockItem({
    required this.stockCode,
    required this.stockName,
    required this.remainderQuantity,
    required this.evaluationAmount,
    required this.profitRate,
  });

  factory DailyStockItem.fromJson(Map<String, dynamic> json) {
    return DailyStockItem(
      stockCode: json['stockCode'] as String? ?? '',
      stockName: json['stockName'] as String? ?? '',
      remainderQuantity: json['remainderQuantity'] as String?,
      evaluationAmount: json['evaluationAmount'] as String?,
      profitRate: json['profitRate'] as String?,
    );
  }

  final String stockCode;
  final String stockName;
  final String? remainderQuantity;
  final String? evaluationAmount;
  final String? profitRate;
}

class DailyBalanceInfo {
  DailyBalanceInfo({
    required this.date,
    required this.totalBuyAmount,
    required this.totalEvaluationAmount,
    required this.totalEvaluationProfit,
    required this.totalProfitRate,
    required this.dailyBalanceRate,
  });

  factory DailyBalanceInfo.fromJson(Map<String, dynamic> json) {
    final items = json['dailyBalanceRate'] as List<dynamic>? ?? [];
    return DailyBalanceInfo(
      date: json['date'] as String?,
      totalBuyAmount: json['totalBuyAmount'] as String?,
      totalEvaluationAmount: json['totalEvaluationAmount'] as String?,
      totalEvaluationProfit: json['totalEvaluationProfit'] as String?,
      totalProfitRate: json['totalProfitRate'] as String?,
      dailyBalanceRate: items.map((e) => DailyStockItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  final String? date;
  final String? totalBuyAmount;
  final String? totalEvaluationAmount;
  final String? totalEvaluationProfit;
  final String? totalProfitRate;
  final List<DailyStockItem> dailyBalanceRate;
}

class StockEvaluationItem {
  StockEvaluationItem({
    required this.stockCode,
    required this.stockName,
    required this.remainingQuantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.evaluationAmount,
    required this.profitLossAmount,
    required this.profitLossRate,
  });

  factory StockEvaluationItem.fromJson(Map<String, dynamic> json) {
    return StockEvaluationItem(
      stockCode: json['stockCode'] as String? ?? '',
      stockName: json['stockName'] as String? ?? '',
      remainingQuantity: json['remainingQuantity'] as String?,
      averagePrice: json['averagePrice'] as String?,
      currentPrice: json['currentPrice'] as String?,
      evaluationAmount: json['evaluationAmount'] as String?,
      profitLossAmount: json['profitLossAmount'] as String?,
      profitLossRate: json['profitLossRate'] as String?,
    );
  }

  final String stockCode;
  final String stockName;
  final String? remainingQuantity;
  final String? averagePrice;
  final String? currentPrice;
  final String? evaluationAmount;
  final String? profitLossAmount;
  final String? profitLossRate;
}

class AccountEvaluationInfo {
  AccountEvaluationInfo({
    required this.deposit,
    required this.totalEstimatedAmount,
    required this.assetEvaluationAmount,
    required this.accumulatedProfitLoss,
    required this.accumulatedProfitRate,
    required this.stockEvaluations,
  });

  factory AccountEvaluationInfo.fromJson(Map<String, dynamic> json) {
    final items = json['stockEvaluations'] as List<dynamic>? ?? [];
    return AccountEvaluationInfo(
      deposit: json['deposit'] as String?,
      totalEstimatedAmount: json['totalEstimatedAmount'] as String?,
      assetEvaluationAmount: json['assetEvaluationAmount'] as String?,
      accumulatedProfitLoss: json['accumulatedProfitLoss'] as String?,
      accumulatedProfitRate: json['accumulatedProfitRate'] as String?,
      stockEvaluations: items.map((e) => StockEvaluationItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  final String? deposit;
  final String? totalEstimatedAmount;
  final String? assetEvaluationAmount;
  final String? accumulatedProfitLoss;
  final String? accumulatedProfitRate;
  final List<StockEvaluationItem> stockEvaluations;
}
