import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/dashboard.dart';

class AdminDashboardApiException implements Exception {
  AdminDashboardApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminDashboardApi {
  AdminDashboardApi(this._client);

  final ApiClient _client;

  Future<List<VisitorTrendPoint>> getVisitorTrend({int days = 7}) async {
    final response = await _get<List<dynamic>>(
      '/api/admin/dashboard/stats/visitors/trend',
      {'days': days},
    );
    return response.map((e) => VisitorTrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BoardActivityPoint>> getBoardDistribution({int days = 7}) async {
    final response = await _get<List<dynamic>>(
      '/api/admin/dashboard/stats/boards/distribution',
      {'days': days},
    );
    return response.map((e) => BoardActivityPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RoleDistributionPoint>> getRoleDistribution() async {
    final response = await _get<List<dynamic>>('/api/admin/dashboard/stats/users/distribution', {});
    return response.map((e) => RoleDistributionPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminActivityLogItem>> getActivities({int page = 0, int size = 30}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/dashboard/activities',
        queryParameters: {'page': page, 'size': size},
      );
      final content = response.data?['content'] as List<dynamic>? ?? [];
      return content.map((e) => AdminActivityLogItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AdminDashboardApiException(_extractMessage(e) ?? '활동 로그를 불러오지 못했습니다.');
    }
  }

  Future<T> _get<T>(String path, Map<String, dynamic> queryParameters) async {
    try {
      final response = await _client.dio.get<T>(path, queryParameters: queryParameters);
      return response.data as T;
    } on DioException catch (e) {
      throw AdminDashboardApiException(_extractMessage(e) ?? '통계를 불러오지 못했습니다.');
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
