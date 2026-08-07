import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/feedback.dart';
import '../models/point_history.dart';

class AdminFeedbackApiException implements Exception {
  AdminFeedbackApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminFeedbackApi {
  AdminFeedbackApi(this._client);

  final ApiClient _client;

  Future<PageResult<FeedbackItem>> getFeedbacks({int page = 0, int size = 20}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/feedbacks',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResult.fromJson(response.data!, FeedbackItem.fromJson);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] is String) ? data['message'] as String : null;
      throw AdminFeedbackApiException(message ?? '피드백을 불러오지 못했습니다.');
    }
  }
}
