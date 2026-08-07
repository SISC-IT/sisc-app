import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/bet_round.dart';
import '../models/user_bet.dart';

class BettingApiException implements Exception {
  BettingApiException(this.message, {this.notBettingTime = false});
  final String message;
  final bool notBettingTime;

  @override
  String toString() => message;
}

class BettingApi {
  BettingApi(this._client);

  final ApiClient _client;

  /// 활성 라운드가 없으면 null을 반환한다 (404).
  Future<BetRoundInfo?> getActiveRound(String scope) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/bet-rounds/$scope',
      );
      return BetRoundInfo.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw BettingApiException(_extractMessage(e) ?? '라운드를 불러오지 못했습니다.');
    }
  }

  Future<List<UserBetInfo>> getMyBetHistory() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/api/user-bets/history');
      return (response.data ?? [])
          .map((e) => UserBetInfo.fromJson(e as Map<String, dynamic>))
          .where((b) => b.betStatus != 'DELETED')
          .toList();
    } on DioException catch (e) {
      throw BettingApiException(_extractMessage(e) ?? '베팅 이력을 불러오지 못했습니다.');
    }
  }

  Future<UserBetInfo> placeBet({required String roundId, required String option}) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/user-bets',
        data: {
          'roundId': roundId,
          'option': option,
          'isFree': true,
          'stakePoints': 0,
        },
      );
      return UserBetInfo.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw BettingApiException('베팅 가능 시간이 아니거나 이미 베팅했습니다.', notBettingTime: true);
      }
      throw BettingApiException(_extractMessage(e) ?? '베팅에 실패했습니다.');
    }
  }

  Future<void> cancelBet(String userBetId) async {
    try {
      await _client.dio.delete('/api/user-bets/$userBetId');
    } on DioException catch (e) {
      throw BettingApiException(_extractMessage(e) ?? '베팅 취소에 실패했습니다.');
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
