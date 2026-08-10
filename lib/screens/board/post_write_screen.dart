import 'package:dio/dio.dart' show MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/board_api.dart';
import '../../core/api_client.dart';
import '../../models/board.dart';
import '../../models/post.dart';
import '../../theme/app_colors.dart';

class PostWriteScreen extends StatefulWidget {
  const PostWriteScreen({
    super.key,
    required this.boards,
    required this.initialBoard,
    this.editingPost,
  });

  final List<BoardInfo> boards;
  final BoardInfo initialBoard;
  final PostItem? editingPost;

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _boardApi = BoardApi(ApiClient.instance);
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late BoardInfo _selectedBoard;
  bool _anonymous = false;
  bool _submitting = false;
  String? _errorMessage;

  final List<PlatformFile> _newFiles = [];
  late List<PostAttachmentItem> _existingAttachments;

  bool get _isEditing => widget.editingPost != null;

  @override
  void initState() {
    super.initState();
    _selectedBoard = widget.initialBoard;
    _existingAttachments = List.of(widget.editingPost?.attachments ?? []);
    if (widget.editingPost != null) {
      _titleController.text = widget.editingPost!.title;
      _contentController.text = widget.editingPost!.content;
      _anonymous = widget.editingPost!.anonymous;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() => _newFiles.addAll(result.files));
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = '제목과 내용을 입력해주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final files = _newFiles
          .map((f) => MultipartFile.fromBytes(f.bytes!, filename: f.name))
          .toList();
      if (_isEditing) {
        await _boardApi.updatePost(
          postId: widget.editingPost!.postId,
          boardId: _selectedBoard.boardId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          anonymous: _anonymous,
          existingAttachmentIds: _existingAttachments.map((a) => a.id).toList(),
          files: files,
        );
      } else {
        await _boardApi.createPost(
          boardId: _selectedBoard.boardId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          anonymous: _anonymous,
          files: files,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '게시글 수정' : '글쓰기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isEditing)
              DropdownButtonFormField<BoardInfo>(
                initialValue: _selectedBoard,
                decoration: const InputDecoration(labelText: '게시판'),
                items: widget.boards
                    .map((b) => DropdownMenuItem(value: b, child: Text(b.boardName)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedBoard = value);
                },
              )
            else
              InputDecorator(
                decoration: const InputDecoration(labelText: '게시판'),
                child: Text(_selectedBoard.boardName),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: '내용', alignLabelWithHint: true),
              maxLines: 10,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v ?? false),
              title: const Text('익명으로 작성'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('파일/이미지 첨부'),
            ),
            if (_existingAttachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._existingAttachments.map(
                (a) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(a.originalFilename, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _existingAttachments.remove(a)),
                  ),
                ),
              ),
            ],
            if (_newFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._newFiles.map(
                (f) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(f.name, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _newFiles.remove(f)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: context.appColors.destructive),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? '수정 완료' : '작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
