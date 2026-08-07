import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/admin_user.dart';

class AdminUserApiException implements Exception {
  AdminUserApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExcelSyncResult {
  ExcelSyncResult({required this.createdCount, required this.updatedCount});

  factory ExcelSyncResult.fromJson(Map<String, dynamic> json) {
    return ExcelSyncResult(
      createdCount: json['createdCount'] as int? ?? 0,
      updatedCount: json['updatedCount'] as int? ?? 0,
    );
  }

  final int createdCount;
  final int updatedCount;
}

class AdminUserApi {
  AdminUserApi(this._client);

  final ApiClient _client;

  Future<List<AdminUserInfo>> getUsers({
    String? keyword,
    int? generation,
    String? role,
    String? status,
  }) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/api/admin/users',
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (generation != null) 'generation': generation,
          if (role != null) 'role': role,
          if (status != null) 'status': status,
        },
      );
      return (response.data ?? [])
          .map((e) => AdminUserInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AdminUserApiException(_extractMessage(e) ?? '회원 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> updateStatus(String userId, String status) async {
    await _patch('/api/admin/users/$userId/status', {'status': status});
  }

  Future<void> updateRole(String userId, String role) async {
    await _patch('/api/admin/users/$userId/role', {'role': role});
  }

  Future<void> updateGrade(String userId, String grade) async {
    await _patch('/api/admin/users/$userId/grade', {'grade': grade});
  }

  Future<void> _patch(String path, Map<String, dynamic> queryParameters) async {
    try {
      await _client.dio.patch(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw AdminUserApiException(_extractMessage(e) ?? '변경에 실패했습니다.');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _client.dio.delete('/api/admin/users/$userId');
    } on DioException catch (e) {
      throw AdminUserApiException(_extractMessage(e) ?? '삭제에 실패했습니다.');
    }
  }

  Future<ExcelSyncResult> uploadExcel({required List<int> bytes, required String filename}) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/admin/users/upload-excel',
        data: formData,
      );
      return ExcelSyncResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw AdminUserApiException(_extractMessage(e) ?? '엑셀 업로드에 실패했습니다.');
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
