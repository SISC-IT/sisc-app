import 'package:flutter/material.dart';

import '../../api/public_page_api.dart';
import '../../core/api_client.dart';

class PublicPagesScreen extends StatefulWidget {
  const PublicPagesScreen({super.key});

  @override
  State<PublicPagesScreen> createState() => _PublicPagesScreenState();
}

class _PublicPagesScreenState extends State<PublicPagesScreen> with SingleTickerProviderStateMixin {
  final _api = PublicPageApi(ApiClient.instance);
  late final TabController _tabController;

  static const _pageTypes = ['CLUB', 'EXECUTIVES'];
  static const _pageLabels = {'CLUB': '동아리 소개', 'EXECUTIVES': '임원 소개'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pageTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공개 페이지 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _pageTypes.map((t) => Tab(text: _pageLabels[t])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _pageTypes.map((t) => _PublicPageEditor(api: _api, pageType: t)).toList(),
      ),
    );
  }
}

class _PublicPageEditor extends StatefulWidget {
  const _PublicPageEditor({required this.api, required this.pageType});

  final PublicPageApi api;
  final String pageType;

  @override
  State<_PublicPageEditor> createState() => _PublicPageEditorState();
}

class _PublicPageEditorState extends State<_PublicPageEditor> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _publishedAt;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await widget.api.getPage(widget.pageType);
      setState(() {
        _titleController.text = page?.title ?? '';
        _contentController.text = page?.contentText ?? '';
        _publishedAt = page?.publishedAt;
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.api.savePage(
        pageType: widget.pageType,
        title: _titleController.text.trim(),
        text: _contentController.text,
      );
      setState(() {
        _message = '저장되었습니다.';
        _isError = false;
      });
      _load();
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_publishedAt != null)
            Text('마지막 발행: $_publishedAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(labelText: '내용', alignLabelWithHint: true),
            maxLines: 16,
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_message!, style: TextStyle(color: _isError ? Colors.red : Colors.green)),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장'),
          ),
        ],
      ),
    );
  }
}
