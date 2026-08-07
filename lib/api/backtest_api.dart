import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/backtest.dart';

class BacktestApiException implements Exception {
  BacktestApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BacktestApi {
  BacktestApi(this._client);

  final ApiClient _client;

  Future<List<String>> getAvailableTickers() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>('/api/backtest/stocks/info');
      return BacktestResult.fromJson(response.data!).availableTickers;
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '종목 정보를 불러오지 못했습니다.');
    }
  }

  Future<BacktestResult> runBacktest({
    required String title,
    required String startDate,
    required String endDate,
    required Map<String, dynamic> strategy,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/backtest/runs',
        data: {
          'title': title,
          'startDate': startDate,
          'endDate': endDate,
          'strategy': strategy,
        },
      );
      return BacktestResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '백테스트 실행에 실패했습니다.');
    }
  }

  Future<BacktestResult> getStatus(int runId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/backtest/runs/$runId/status',
      );
      return BacktestResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '진행 상태를 불러오지 못했습니다.');
    }
  }

  Future<BacktestResult> getRunDetail(int runId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>('/api/backtest/runs/$runId');
      return BacktestResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '결과를 불러오지 못했습니다.');
    }
  }

  Future<void> deleteRun(int runId) async {
    try {
      await _client.dio.delete('/api/backtest/runs/$runId');
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '삭제에 실패했습니다.');
    }
  }

  Future<void> saveRunToTemplate({required int runId, required String templateId}) async {
    try {
      await _client.dio.patch(
        '/api/backtest/runs/$runId',
        data: {'backtestRunId': runId, 'templateId': templateId},
      );
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '템플릿 저장에 실패했습니다.');
    }
  }

  Future<void> deleteRunsFromTemplate({required String templateId, required List<int> runIds}) async {
    try {
      await _client.dio.delete(
        '/api/backtest/templates/$templateId/runs',
        data: {'backtestRunIds': runIds},
      );
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '삭제에 실패했습니다.');
    }
  }

  Future<List<TemplateInfo>> getTemplates() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>('/api/backtest/templates');
      return TemplateDetail.fromJson(response.data!).templates;
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '템플릿 목록을 불러오지 못했습니다.');
    }
  }

  Future<TemplateDetail> getTemplateDetail(String templateId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/backtest/templates/$templateId',
      );
      return TemplateDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '템플릿을 불러오지 못했습니다.');
    }
  }

  Future<TemplateInfo> createTemplate({
    required String title,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/backtest/templates',
        data: {'title': title, 'description': description, 'isPublic': isPublic},
      );
      return TemplateDetail.fromJson(response.data!).template!;
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '템플릿 생성에 실패했습니다.');
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await _client.dio.delete('/api/backtest/templates/$templateId');
    } on DioException catch (e) {
      throw BacktestApiException(_extractMessage(e) ?? '템플릿 삭제에 실패했습니다.');
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
