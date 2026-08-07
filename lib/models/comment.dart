class CommentItem {
  CommentItem({
    required this.commentId,
    required this.authorId,
    required this.userName,
    required this.content,
    required this.anonymous,
    required this.createdDate,
    required this.parentCommentId,
    required this.replies,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return CommentItem(
      commentId: json['commentId'] as String,
      authorId: user?['id'] as String?,
      userName: user?['name'] as String? ?? '알 수 없음',
      content: json['content'] as String? ?? '',
      anonymous: json['anonymous'] as bool? ?? false,
      createdDate: json['createdDate'] as String? ?? '',
      parentCommentId: json['parentCommentId'] as String?,
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String commentId;
  final String? authorId;
  final String userName;
  final String content;
  final bool anonymous;
  final String createdDate;
  final String? parentCommentId;
  final List<CommentItem> replies;
}
