import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/attendance_session.dart';

class AttendanceAdminApiException implements Exception {
  AttendanceAdminApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AttendanceAdminApi {
  AttendanceAdminApi(this._client);

  final ApiClient _client;

  Future<List<AttendanceSessionInfo>> getSessions() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/api/attendance/sessions');
      return (response.data ?? [])
          .map((e) => AttendanceSessionInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '세션 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> createSession({
    required String title,
    required String description,
    required int allowedMinutes,
  }) async {
    try {
      await _client.dio.post(
        '/api/attendance/sessions',
        data: {
          'title': title,
          'description': description,
          'allowedMinutes': allowedMinutes,
          'status': 'OPEN',
        },
      );
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '세션 생성에 실패했습니다.');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _client.dio.delete('/api/attendance/sessions/$sessionId');
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '세션 삭제에 실패했습니다.');
    }
  }

  Future<void> closeSession(String sessionId) async {
    try {
      await _client.dio.post('/api/attendance/sessions/$sessionId/close');
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '세션 종료에 실패했습니다.');
    }
  }

  Future<List<AttendanceRoundInfo>> getRounds(String sessionId) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/api/attendance/sessions/$sessionId/rounds',
      );
      return (response.data ?? [])
          .map((e) => AttendanceRoundInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '회차 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> createRound({
    required String sessionId,
    required String roundDate,
    required String startAt,
    required String closeAt,
    required String roundName,
    required String locationName,
  }) async {
    try {
      await _client.dio.post(
        '/api/attendance/sessions/$sessionId/rounds',
        data: {
          'roundDate': roundDate,
          'startAt': startAt,
          'closeAt': closeAt,
          'roundName': roundName,
          'locationName': locationName,
        },
      );
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '회차 생성에 실패했습니다.');
    }
  }

  Future<void> deleteRound(String roundId) async {
    try {
      await _client.dio.delete('/api/attendance/rounds/$roundId');
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '회차 삭제에 실패했습니다.');
    }
  }

  Future<SessionAttendanceTable> getAttendanceTable(String sessionId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/attendance/sessions/$sessionId/users',
      );
      return SessionAttendanceTable.fromJson(response.data!);
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '출석부를 불러오지 못했습니다.');
    }
  }

  Future<List<AvailableSessionUser>> getAvailableUsers(String sessionId) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/api/attendance/sessions/$sessionId/users/available',
      );
      return (response.data ?? [])
          .map((e) => AvailableSessionUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '추가 가능한 회원을 불러오지 못했습니다.');
    }
  }

  Future<void> addUserToSession(String sessionId, String userId) async {
    try {
      await _client.dio.post(
        '/api/attendance/sessions/$sessionId/users',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '회원 추가에 실패했습니다.');
    }
  }

  Future<void> removeUserFromSession(String sessionId, String userId) async {
    try {
      await _client.dio.delete('/api/attendance/sessions/$sessionId/users/$userId');
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '회원 제거에 실패했습니다.');
    }
  }

  Future<void> addAllUsers(String sessionId) async {
    try {
      await _client.dio.post('/api/attendance/sessions/$sessionId/users/add-all');
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '전체 회원 추가에 실패했습니다.');
    }
  }

  Future<void> updateAttendanceStatus({
    required String roundId,
    required String userId,
    required String status,
    String reason = '관리자에 의한 출석 상태 변경',
  }) async {
    try {
      await _client.dio.put(
        '/api/attendance/rounds/$roundId/users/$userId',
        data: {'status': status, 'reason': reason},
      );
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? '출석 상태 변경에 실패했습니다.');
    }
  }

  Future<AttendanceRoundQrToken> issueQrToken(String roundId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/attendance/rounds/$roundId/qr-token',
      );
      return AttendanceRoundQrToken.fromJson(response.data!);
    } on DioException catch (e) {
      throw AttendanceAdminApiException(_extractMessage(e) ?? 'QR 토큰 발급에 실패했습니다.');
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

class AttendanceRoundQrToken {
  AttendanceRoundQrToken({required this.roundId, required this.qrToken, required this.expiresAtEpochSec});

  factory AttendanceRoundQrToken.fromJson(Map<String, dynamic> json) {
    return AttendanceRoundQrToken(
      roundId: json['roundId'] as String,
      qrToken: json['qrToken'] as String,
      expiresAtEpochSec: json['expiresAtEpochSec'] as int,
    );
  }

  final String roundId;
  final String qrToken;
  final int expiresAtEpochSec;
}
