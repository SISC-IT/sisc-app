import 'board.dart';
import 'comment.dart';
import 'point_history.dart';

class PostAttachmentItem {
  PostAttachmentItem({
    required this.id,
    required this.savedFilename,
    required this.originalFilename,
  });

  factory PostAttachmentItem.fromJson(Map<String, dynamic> json) {
    return PostAttachmentItem(
      id: json['postAttachmentId'] as String,
      savedFilename: json['savedFilename'] as String? ?? '',
      originalFilename: json['originalFilename'] as String? ?? '',
    );
  }

  final String id;
  final String savedFilename;
  final String originalFilename;
}

class PostItem {
  PostItem({
    required this.postId,
    required this.board,
    required this.authorId,
    required this.userName,
    required this.title,
    required this.content,
    required this.contentFormat,
    required this.contentHtml,
    required this.anonymous,
    required this.likeCount,
    required this.commentCount,
    required this.bookmarkCount,
    required this.isLiked,
    required this.isBookmarked,
    required this.createdDate,
    required this.attachments,
    required this.comments,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final board = json['board'] as Map<String, dynamic>?;
    final commentsJson = json['comments'] as Map<String, dynamic>?;
    return PostItem(
      postId: json['postId'] as String,
      board: board != null ? BoardInfo.fromJson(board) : null,
      authorId: user?['id'] as String?,
      userName: user?['name'] as String? ?? '알 수 없음',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      contentFormat: json['contentFormat'] as String? ?? 'PLAIN_TEXT',
      contentHtml: json['contentHtml'] as String?,
      anonymous: json['anonymous'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      bookmarkCount: json['bookmarkCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      createdDate: json['createdDate'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => PostAttachmentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: commentsJson != null
          ? PageResult.fromJson(commentsJson, CommentItem.fromJson)
          : null,
    );
  }

  final String postId;
  final BoardInfo? board;
  final String? authorId;
  final String userName;
  final String title;
  final String content;
  final String contentFormat;
  final String? contentHtml;
  final bool anonymous;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final bool isLiked;
  final bool isBookmarked;
  final String createdDate;
  final List<PostAttachmentItem> attachments;
  final PageResult<CommentItem>? comments;

  bool get isRichHtml => contentFormat == 'TIPTAP_JSON' && (contentHtml?.isNotEmpty ?? false);
}
