import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/board.dart';
import '../models/point_history.dart';
import '../models/post.dart';

class BoardApiException implements Exception {
  BoardApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BoardApi {
  BoardApi(this._client);

  final ApiClient _client;

  Future<List<BoardInfo>> getParentBoards() => _getBoards('/api/board/parents');

  Future<List<BoardInfo>> getChildBoards() => _getBoards('/api/board/childs');

  Future<void> createBoard({required String boardName, String? parentBoardId}) async {
    try {
      await _client.dio.post(
        '/api/admin/board',
        data: {'boardName': boardName, 'parentBoardId': parentBoardId},
      );
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시판 생성에 실패했습니다.');
    }
  }

  Future<void> deleteBoard(String boardId) async {
    try {
      await _client.dio.delete('/api/admin/board/$boardId');
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시판 삭제에 실패했습니다.');
    }
  }

  Future<List<BoardInfo>> _getBoards(String path) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(path);
      return (response.data ?? [])
          .map((e) => BoardInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시판 목록을 불러오지 못했습니다.');
    }
  }

  Future<PageResult<PostItem>> getPosts({
    required String boardId,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/board/posts',
        queryParameters: {
          'boardId': boardId,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      return PageResult.fromJson(response.data!, PostItem.fromJson);
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시글을 불러오지 못했습니다.');
    }
  }

  Future<PageResult<PostItem>> searchPosts({
    required String boardId,
    required String keyword,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/board/posts/search',
        queryParameters: {
          'boardId': boardId,
          'keyword': keyword,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      return PageResult.fromJson(response.data!, PostItem.fromJson);
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '검색에 실패했습니다.');
    }
  }

  Future<PostItem> getPostDetail(
    String postId, {
    int commentPageNumber = 0,
    int commentPageSize = 50,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/board/post/$postId',
        queryParameters: {
          'commentPageNumber': commentPageNumber,
          'commentPageSize': commentPageSize,
        },
      );
      return PostItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시글을 불러오지 못했습니다.');
    }
  }

  Future<void> createPost({
    required String boardId,
    required String title,
    required String content,
    required bool anonymous,
    List<MultipartFile> files = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'boardId': boardId,
        'title': title,
        'content': content,
        'anonymous': anonymous,
        if (files.isNotEmpty) 'files': files,
      });
      await _client.dio.post('/api/board/post', data: formData);
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시글 작성에 실패했습니다.');
    }
  }

  Future<void> updatePost({
    required String postId,
    required String boardId,
    required String title,
    required String content,
    required bool anonymous,
    List<String> existingAttachmentIds = const [],
    List<MultipartFile> files = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'boardId': boardId,
        'title': title,
        'content': content,
        'anonymous': anonymous,
        if (existingAttachmentIds.isNotEmpty)
          'existingAttachmentIds': existingAttachmentIds,
        if (files.isNotEmpty) 'files': files,
      });
      await _client.dio.put('/api/board/post/$postId', data: formData);
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시글 수정에 실패했습니다.');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _client.dio.delete('/api/board/post/$postId');
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '게시글 삭제에 실패했습니다.');
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      await _client.dio.post('/api/board/$postId/like');
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '좋아요 처리에 실패했습니다.');
    }
  }

  Future<void> toggleBookmark(String postId) async {
    try {
      await _client.dio.post('/api/board/$postId/bookmark');
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '북마크 처리에 실패했습니다.');
    }
  }

  Future<void> createComment({
    required String postId,
    required String content,
    required bool anonymous,
    String? parentCommentId,
  }) async {
    try {
      await _client.dio.post(
        '/api/board/comment',
        data: {
          'postId': postId,
          'content': content,
          'anonymous': anonymous,
          'parentCommentId': parentCommentId,
        },
      );
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '댓글 작성에 실패했습니다.');
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String postId,
    required String content,
    bool anonymous = false,
    String? parentCommentId,
  }) async {
    try {
      await _client.dio.put(
        '/api/board/comment/$commentId',
        data: {
          'postId': postId,
          'content': content,
          'anonymous': anonymous,
          'parentCommentId': parentCommentId,
        },
      );
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '댓글 수정에 실패했습니다.');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.dio.delete('/api/board/comment/$commentId');
    } on DioException catch (e) {
      throw BoardApiException(_extractMessage(e) ?? '댓글 삭제에 실패했습니다.');
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
