import 'dart:convert';

class BacktestRunInfo {
  BacktestRunInfo({
    required this.id,
    required this.title,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.paramsJson,
    required this.errorMessage,
    required this.templateId,
  });

  factory BacktestRunInfo.fromJson(Map<String, dynamic> json) {
    final template = json['template'] as Map<String, dynamic>?;
    return BacktestRunInfo(
      id: json['id'] as int,
      title: json['title'] as String? ?? '백테스트 결과',
      status: json['status'] as String? ?? 'PENDING',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      paramsJson: json['paramsJson'] as String?,
      errorMessage: json['errorMessage'] as String?,
      templateId: template?['templateId'] as String?,
    );
  }

  final int id;
  final String title;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? paramsJson;
  final String? errorMessage;
  final String? templateId;

  bool get isFinal => status == 'COMPLETED' || status == 'FAILED';

  Map<String, dynamic> get strategyParams {
    if (paramsJson == null) return {};
    try {
      final parsed = jsonDecode(paramsJson!);
      if (parsed is! Map<String, dynamic>) return {};
      return (parsed['strategy'] as Map<String, dynamic>?) ?? parsed;
    } catch (_) {
      return {};
    }
  }
}

class BacktestMetricsInfo {
  BacktestMetricsInfo({
    required this.totalReturn,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.avgHoldDays,
    required this.tradesCount,
    required this.assetCurveJson,
  });

  factory BacktestMetricsInfo.fromJson(Map<String, dynamic> json) {
    return BacktestMetricsInfo(
      totalReturn: (json['totalReturn'] as num?)?.toDouble() ?? 0,
      maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0,
      sharpeRatio: (json['sharpeRatio'] as num?)?.toDouble() ?? 0,
      avgHoldDays: (json['avgHoldDays'] as num?)?.toDouble() ?? 0,
      tradesCount: json['tradesCount'] as int? ?? 0,
      assetCurveJson: json['assetCurveJson'] as String?,
    );
  }

  final double totalReturn;
  final double maxDrawdown;
  final double sharpeRatio;
  final double avgHoldDays;
  final int tradesCount;
  final String? assetCurveJson;

  List<double> get equityCurve {
    if (assetCurveJson == null) return [];
    try {
      final parsed = jsonDecode(assetCurveJson!);
      if (parsed is! List) return [];
      return parsed.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return [];
    }
  }
}

class BacktestResult {
  BacktestResult({required this.run, required this.metrics, required this.availableTickers});

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    final run = json['backtestRun'] as Map<String, dynamic>?;
    final metrics = json['backtestRunMetricsResponse'] as Map<String, dynamic>?;
    final tickers = json['availableTickers'] as List<dynamic>?;
    return BacktestResult(
      run: run != null ? BacktestRunInfo.fromJson(run) : null,
      metrics: metrics != null ? BacktestMetricsInfo.fromJson(metrics) : null,
      availableTickers: tickers?.map((e) => e as String).toList() ?? [],
    );
  }

  final BacktestRunInfo? run;
  final BacktestMetricsInfo? metrics;
  final List<String> availableTickers;
}

class TemplateInfo {
  TemplateInfo({
    required this.templateId,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.bookmarkCount,
    required this.likeCount,
  });

  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(
      templateId: json['templateId'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      bookmarkCount: json['bookmarkCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }

  final String templateId;
  final String title;
  final String? description;
  final bool isPublic;
  final int bookmarkCount;
  final int likeCount;
}

class TemplateDetail {
  TemplateDetail({required this.templates, required this.template, required this.runs});

  factory TemplateDetail.fromJson(Map<String, dynamic> json) {
    final templates = json['templates'] as List<dynamic>?;
    final template = json['template'] as Map<String, dynamic>?;
    final runs = json['backtestRuns'] as List<dynamic>?;
    return TemplateDetail(
      templates: templates?.map((e) => TemplateInfo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      template: template != null ? TemplateInfo.fromJson(template) : null,
      runs: runs?.map((e) => BacktestRunInfo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  final List<TemplateInfo> templates;
  final TemplateInfo? template;
  final List<BacktestRunInfo> runs;
}
