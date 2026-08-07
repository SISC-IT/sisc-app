import 'package:dio/dio.dart';

import '../core/api_client.dart';

class FeedbackApiException implements Exception {
  FeedbackApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FeedbackApi {
  FeedbackApi(this._client);

  final ApiClient _client;

  Future<void> submitFeedback(String content) async {
    try {
      await _client.dio.post('/api/user/feedbacks', data: {'content': content});
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] is String) ? data['message'] as String : null;
      throw FeedbackApiException(message ?? '피드백 등록에 실패했습니다.');
    }
  }
}
