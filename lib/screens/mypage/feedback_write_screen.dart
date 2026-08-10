import 'package:flutter/material.dart';

import '../../api/feedback_api.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';

class FeedbackWriteScreen extends StatefulWidget {
  const FeedbackWriteScreen({super.key});

  @override
  State<FeedbackWriteScreen> createState() => _FeedbackWriteScreenState();
}

class _FeedbackWriteScreenState extends State<FeedbackWriteScreen> {
  final _api = FeedbackApi(ApiClient.instance);
  final _contentController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = '피드백 내용을 입력해주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _api.submitFeedback(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드백이 접수되었습니다. 감사합니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('피드백 작성')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '솔직한 피드백은 큰 도움이 됩니다. 피드백은 익명으로 저장됩니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 1000,
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: TextStyle(color: context.appColors.destructive)),
              ),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('피드백 작성하기'),
            ),
          ],
        ),
      ),
    );
  }
}
