import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/asset_management.dart';

class AssetManagementApiException implements Exception {
  AssetManagementApiException(this.message, {this.forbidden = false});
  final String message;
  final bool forbidden;

  @override
  String toString() => message;
}

class AssetManagementApi {
  AssetManagementApi(this._client);

  final ApiClient _client;

  Future<bool> checkAccess() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/asset-management/accounts/access',
      );
      return response.data?['canView'] as bool? ?? false;
    } on DioException {
      return false;
    }
  }

  Future<List<AccountBalanceInfo>> getAccounts() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/api/asset-management/accounts');
      return (response.data ?? [])
          .map((e) => AccountBalanceInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _wrap(e, '계좌 목록을 불러오지 못했습니다.');
    }
  }

  /// [date]는 yyyyMMdd 형식. null이면 서버가 오늘 날짜로 처리한다.
  Future<DailyBalanceInfo> getDailyBalance(String? date) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/asset-management/accounts/daily-balance',
        queryParameters: date != null ? {'date': date} : null,
      );
      return DailyBalanceInfo.fromJson(response.data!);
    } on DioException catch (e) {
      throw _wrap(e, '일별 잔고를 불러오지 못했습니다.');
    }
  }

  Future<AccountEvaluationInfo> getEvaluation(String exchangeType) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/asset-management/accounts/evaluation',
        queryParameters: {'exchangeType': exchangeType},
      );
      return AccountEvaluationInfo.fromJson(response.data!);
    } on DioException catch (e) {
      throw _wrap(e, '계좌 평가 현황을 불러오지 못했습니다.');
    }
  }

  AssetManagementApiException _wrap(DioException e, String fallback) {
    if (e.response?.statusCode == 403) {
      return AssetManagementApiException('자산운용팀 계좌 조회 권한이 없습니다.', forbidden: true);
    }
    final data = e.response?.data;
    final message = (data is Map && data['message'] is String) ? data['message'] as String : null;
    return AssetManagementApiException(message ?? fallback);
  }
}
