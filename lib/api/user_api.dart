import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/activity_log.dart';
import '../models/point_history.dart';
import '../models/user_info.dart';

class UserApiException implements Exception {
  UserApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  Future<UserInfoResponse> getDetails() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/user/details',
      );
      return UserInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw UserApiException(_extractMessage(e) ?? '내 정보를 불러오지 못했습니다.');
    }
  }

  Future<void> updateEmail(String email) async {
    await _updateDetails({'email': email});
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _updateDetails({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> _updateDetails(Map<String, dynamic> data) async {
    try {
      await _client.dio.patch('/api/user/details', data: data);
    } on DioException catch (e) {
      throw UserApiException(_extractMessage(e) ?? '정보 수정에 실패했습니다.');
    }
  }

  Future<void> withdraw() async {
    try {
      await _client.dio.delete('/api/user/withdraw');
    } on DioException catch (e) {
      throw UserApiException(_extractMessage(e) ?? '회원 탈퇴에 실패했습니다.');
    } finally {
      await _client.clearSession();
    }
  }

  Future<PageResult<ActivityLogItem>> getAttendanceLogs({
    int page = 0,
    int size = 20,
  }) async {
    return _getLogs('/api/user/logs/attendance', page: page, size: size);
  }

  Future<PageResult<ActivityLogItem>> getBoardLogs({
    int page = 0,
    int size = 20,
  }) async {
    return _getLogs('/api/user/logs/board', page: page, size: size);
  }

  Future<PageResult<ActivityLogItem>> _getLogs(
    String path, {
    required int page,
    required int size,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'size': size},
      );
      return PageResult.fromJson(response.data!, ActivityLogItem.fromJson);
    } on DioException catch (e) {
      throw UserApiException(_extractMessage(e) ?? '활동 내역을 불러오지 못했습니다.');
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
