import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/attendance.dart';

class CheckInException implements Exception {
  CheckInException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AttendanceApi {
  AttendanceApi(this._client);

  final ApiClient _client;

  Future<void> checkIn(String qrToken) async {
    try {
      await _client.dio.post(
        '/api/attendance/check-in',
        data: {'qrToken': qrToken},
      );
    } on DioException catch (e) {
      throw CheckInException(_extractMessage(e) ?? '출석 체크에 실패했습니다.');
    }
  }

  Future<List<AttendanceRecord>> getMyAttendances() async {
    final response = await _client.dio.get<List<dynamic>>('/api/attendance/me');
    final data = response.data ?? [];
    return data
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
