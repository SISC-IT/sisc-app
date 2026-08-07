import 'package:dio/dio.dart';

import '../core/api_client.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<void> login({required String studentId, required String password}) async {
    try {
      await _client.dio.post(
        '/api/auth/login',
        data: {'studentId': studentId, 'password': password},
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractMessage(e) ?? '로그인에 실패했습니다.');
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/api/auth/logout');
    } on DioException catch (_) {
      // 로그아웃은 실패해도 로컬 세션을 지우면 그만이므로 무시한다.
    } finally {
      await _client.clearSession();
    }
  }

  Future<void> signup({
    required String name,
    required String studentId,
    required String password,
    required String phoneNumber,
    required String email,
    required String gender,
    required String college,
    required String department,
    required int generation,
    required String teamName,
    String? remark,
  }) async {
    try {
      await _client.dio.post(
        '/api/auth/signup',
        data: {
          'name': name,
          'studentId': studentId,
          'password': password,
          'phoneNumber': phoneNumber,
          'email': email,
          'gender': gender,
          'college': college,
          'department': department,
          'generation': generation,
          'teamName': teamName,
          'remark': remark,
        },
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractMessage(e) ?? '회원가입에 실패했습니다.');
    }
  }

  Future<void> sendPasswordResetCode({
    required String email,
    required String studentId,
  }) async {
    try {
      await _client.dio.post(
        '/api/auth/password/reset/send',
        data: {'email': email, 'studentId': studentId},
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractMessage(e) ?? '인증코드 전송에 실패했습니다.');
    }
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String studentId,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post(
        '/api/auth/password/reset/confirm',
        data: {
          'email': email,
          'code': code,
          'studentId': studentId,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractMessage(e) ?? '비밀번호 재설정에 실패했습니다.');
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
