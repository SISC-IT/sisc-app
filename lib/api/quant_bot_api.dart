import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/quant_bot.dart';

class QuantBotApiException implements Exception {
  QuantBotApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class QuantBotApi {
  QuantBotApi(this._client);

  final ApiClient _client;

  Future<PortfolioOverview> getPortfolioOverview() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/quant-bot/portfolio-overview',
      );
      return PortfolioOverview.fromJson(response.data!);
    } on DioException catch (e) {
      throw QuantBotApiException(_extractMessage(e) ?? '자산 현황을 불러오지 못했습니다.');
    }
  }

  Future<List<AssetPoint>> getAssets() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/api/quant-bot/assets');
      return (response.data ?? [])
          .map((e) => AssetPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw QuantBotApiException(_extractMessage(e) ?? '자산 추이를 불러오지 못했습니다.');
    }
  }

  Future<List<PositionInfo>> getPositions() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/api/quant-bot/positions');
      return (response.data ?? [])
          .map((e) => PositionInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw QuantBotApiException(_extractMessage(e) ?? '포지션을 불러오지 못했습니다.');
    }
  }

  Future<List<TradeLogInfo>> getLogs() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/api/quant-bot/logs');
      return (response.data ?? [])
          .map((e) => TradeLogInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw QuantBotApiException(_extractMessage(e) ?? '매매 로그를 불러오지 못했습니다.');
    }
  }

  Future<XaiReportInfo> getReport(int executionId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/quant-bot/report',
        queryParameters: {'executionId': executionId},
      );
      return XaiReportInfo.fromJson(response.data!);
    } on DioException catch (e) {
      throw QuantBotApiException(_extractMessage(e) ?? '리포트를 불러오지 못했습니다.');
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
