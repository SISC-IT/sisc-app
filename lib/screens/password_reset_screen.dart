import 'package:flutter/material.dart';

import '../api/auth_api.dart';
import '../core/api_client.dart';
import '../theme/app_colors.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _authApi = AuthApi(ApiClient.instance);

  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _sending = false;
  bool _codeSent = false;
  bool _submitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _studentIdController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _errorMessage = null;
    });
    try {
      await _authApi.sendPasswordResetCode(
        email: _emailController.text.trim(),
        studentId: _studentIdController.text.trim(),
      );
      setState(() {
        _codeSent = true;
        _infoMessage = '인증코드를 전송했습니다.';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _authApi.confirmPasswordReset(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        studentId: _studentIdController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('비밀번호 재설정'),
          content: const Text('비밀번호가 변경되었습니다. 다시 로그인해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (!mounted) return;
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
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(labelText: '학번'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '가입된 이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _sending ? null : _sendCode,
              child: Text(_sending ? '전송 중...' : (_codeSent ? '인증코드 재전송' : '인증코드 전송')),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: '인증코드 (6자리)'),
              maxLength: 6,
            ),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: '새 비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_infoMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _infoMessage!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
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
                  : const Text('비밀번호 변경'),
            ),
          ],
        ),
      ),
    );
  }
}
