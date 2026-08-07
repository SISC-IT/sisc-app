import 'package:dio/dio.dart';

import '../core/api_client.dart';

class EmailApiException implements Exception {
  EmailApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EmailApi {
  EmailApi(this._client);

  final ApiClient _client;

  Future<void> sendVerification(String email) async {
    try {
      await _client.dio.post(
        '/api/email/send',
        queryParameters: {'email': email},
      );
    } on DioException catch (e) {
      throw EmailApiException(_extractMessage(e) ?? '인증메일 전송에 실패했습니다.');
    }
  }

  Future<void> verify({required String email, required String code}) async {
    try {
      await _client.dio.post(
        '/api/email/verify',
        queryParameters: {'email': email, 'code': code},
      );
    } on DioException catch (e) {
      throw EmailApiException(_extractMessage(e) ?? '인증에 실패했습니다.');
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is String && data.isNotEmpty) {
      return data;
    }
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
