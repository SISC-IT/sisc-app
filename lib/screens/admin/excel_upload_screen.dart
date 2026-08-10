import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/admin_user_api.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({super.key});

  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  final _api = AdminUserApi(ApiClient.instance);

  PlatformFile? _file;
  bool _uploading = false;
  String? _errorMessage;
  ExcelSyncResult? _result;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _file = result.files.first;
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null || file.bytes == null) return;
    setState(() {
      _uploading = true;
      _errorMessage = null;
    });
    try {
      final result = await _api.uploadExcel(bytes: file.bytes!, filename: file.name);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('엑셀 명단 업로드')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '.xlsx 형식의 회원 명단을 업로드하면 학번 기준으로 신규 회원이 생성되고, '
              '기존 회원의 기수/직위가 갱신됩니다. 신규 회원의 초기 비밀번호는 전화번호(숫자만)로 설정됩니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(_file?.name ?? '엑셀 파일 선택'),
              onPressed: _pickFile,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: TextStyle(color: context.appColors.destructive)),
              ),
            if (_result != null)
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '업로드 완료: 신규 ${_result!.createdCount}명, 갱신 ${_result!.updatedCount}명',
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _file != null && !_uploading ? _upload : null,
              child: _uploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
