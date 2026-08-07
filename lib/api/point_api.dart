import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/point_history.dart';

class PointApiException implements Exception {
  PointApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PointApi {
  PointApi(this._client);

  final ApiClient _client;

  Future<PageResult<PointHistoryItem>> getHistory({
    int pageNumber = 0,
    int pageSize = 10,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/points/history',
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      );
      final history = response.data!['history'] as Map<String, dynamic>;
      return PageResult.fromJson(history, PointHistoryItem.fromJson);
    } on DioException catch (e) {
      throw PointApiException(_extractMessage(e) ?? '포인트 내역을 불러오지 못했습니다.');
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
