import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/public_page.dart';

class PublicPageApiException implements Exception {
  PublicPageApiException(this.message, {this.notFound = false});
  final String message;
  final bool notFound;

  @override
  String toString() => message;
}

class PublicPageApi {
  PublicPageApi(this._client);

  final ApiClient _client;

  /// [pageType]: CLUB | EXECUTIVES
  Future<PublicPageInfo?> getPage(String pageType) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/public-pages/$pageType',
      );
      return PublicPageInfo.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw PublicPageApiException(_extractMessage(e) ?? '공개 페이지를 불러오지 못했습니다.');
    }
  }

  Future<void> savePage({required String pageType, required String title, required String text}) async {
    try {
      await _client.dio.put(
        '/api/admin/public-pages/$pageType',
        data: {
          'title': title,
          'contentFormat': 'PLAIN_TEXT',
          'content': text,
          'contentText': text,
          'contentHtml': text,
        },
      );
    } on DioException catch (e) {
      throw PublicPageApiException(_extractMessage(e) ?? '저장에 실패했습니다.');
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
