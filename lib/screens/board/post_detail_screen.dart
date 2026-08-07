import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/board_api.dart';
import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../models/board.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../state/auth_state.dart';
import 'post_write_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.boards,
    required this.authState,
  });

  final String postId;
  final List<BoardInfo> boards;
  final AuthState authState;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _boardApi = BoardApi(ApiClient.instance);
  final _commentController = TextEditingController();
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  PostItem? _post;
  bool _loading = true;
  String? _errorMessage;
  bool _changed = false;
  String? _replyToCommentId;
  bool _submittingComment = false;
  bool _anonymousComment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final post = await _boardApi.getPostDetail(widget.postId);
      setState(() => _post = post);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isOwner =>
      _post?.authorId != null && _post?.authorId == widget.authState.userInfo?.id;

  bool get _isAdmin => widget.authState.userInfo?.isAdmin ?? false;

  Future<void> _toggleLike() async {
    await _boardApi.toggleLike(widget.postId);
    _changed = true;
    _load();
  }

  Future<void> _toggleBookmark() async {
    await _boardApi.toggleBookmark(widget.postId);
    _changed = true;
    _load();
  }

  Future<void> _edit() async {
    final post = _post;
    if (post == null) return;
    final board = widget.boards.firstWhere(
      (b) => b.boardId == post.board?.boardId,
      orElse: () => post.board!,
    );
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostWriteScreen(
          boards: widget.boards,
          initialBoard: board,
          editingPost: post,
        ),
      ),
    );
    if (result == true) {
      _changed = true;
      _load();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _boardApi.deletePost(widget.postId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _submittingComment = true);
    try {
      await _boardApi.createComment(
        postId: widget.postId,
        content: content,
        anonymous: _anonymousComment,
        parentCommentId: _replyToCommentId,
      );
      _commentController.clear();
      _replyToCommentId = null;
      _changed = true;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _editComment(CommentItem comment) async {
    final controller = TextEditingController(text: comment.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('수정'),
          ),
        ],
      ),
    );
    if (newContent == null || newContent.isEmpty || newContent == comment.content) return;
    try {
      await _boardApi.updateComment(
        commentId: comment.commentId,
        postId: widget.postId,
        content: newContent,
        anonymous: comment.anonymous,
        parentCommentId: comment.parentCommentId,
      );
      _changed = true;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _boardApi.deleteComment(comment.commentId);
      _changed = true;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openAttachment(String savedFilename) async {
    final uri = Uri.parse('$apiBaseUrl/uploads/$savedFilename');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _canModifyComment(CommentItem comment) =>
      (comment.authorId != null && comment.authorId == widget.authState.userInfo?.id) || _isAdmin;

  Widget _buildComment(CommentItem comment, {bool isReply = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32 : 0, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text(
                _dateFormat.format(DateTime.tryParse(comment.createdDate) ?? DateTime.now()),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.content),
          Row(
            children: [
              if (!isReply)
                TextButton(
                  onPressed: () => setState(() => _replyToCommentId = comment.commentId),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                  child: const Text('답글', style: TextStyle(fontSize: 12)),
                ),
              if (_canModifyComment(comment)) ...[
                TextButton(
                  onPressed: () => _editComment(comment),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                  child: const Text('수정', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => _deleteComment(comment),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                  child: const Text('삭제', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ],
          ),
          ...comment.replies.map((reply) => _buildComment(reply, isReply: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('게시글'),
          actions: [
            if (_isOwner || _isAdmin)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _edit();
                  if (value == 'delete') _delete();
                },
                itemBuilder: (context) => [
                  if (_isOwner) const PopupMenuItem(value: 'edit', child: Text('수정')),
                  if (_isOwner || _isAdmin) const PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text('불러오기에 실패했습니다: $_errorMessage'))
            : _post == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_post!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_post!.userName, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(
                        _dateFormat.format(DateTime.tryParse(_post!.createdDate) ?? DateTime.now()),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_post!.isRichHtml)
                    Html(data: _post!.contentHtml!)
                  else
                    Text(_post!.content),
                  if (_post!.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('첨부파일', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._post!.attachments.map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(a.originalFilename),
                        onTap: () => _openAttachment(a.savedFilename),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _post!.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _post!.isLiked ? Colors.redAccent : null,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text('${_post!.likeCount}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _post!.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _post!.isBookmarked ? Colors.amber.shade700 : null,
                        ),
                        onPressed: _toggleBookmark,
                      ),
                      Text('${_post!.bookmarkCount}'),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('댓글 ${_post!.commentCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(_post!.comments?.content ?? []).map((c) => _buildComment(c)),
                  const SizedBox(height: 16),
                  if (_replyToCommentId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('답글 작성 중', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _replyToCommentId = null),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(hintText: '댓글을 입력하세요'),
                        ),
                      ),
                      IconButton(
                        icon: _submittingComment
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        onPressed: _submittingComment ? null : _submitComment,
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: _anonymousComment,
                    onChanged: (v) => setState(() => _anonymousComment = v ?? false),
                    title: const Text('익명으로 작성', style: TextStyle(fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
      ),
    );
  }
}
