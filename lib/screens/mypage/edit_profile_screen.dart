import 'package:flutter/material.dart';

import '../../api/email_api.dart';
import '../../api/user_api.dart';
import '../../core/api_client.dart';
import '../../state/auth_state.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('개인정보 수정'),
          bottom: const TabBar(
            tabs: [Tab(text: '이메일 변경'), Tab(text: '비밀번호 변경')],
          ),
        ),
        body: TabBarView(
          children: [
            _EmailChangeTab(authState: authState),
            _PasswordChangeTab(),
          ],
        ),
      ),
    );
  }
}

class _EmailChangeTab extends StatefulWidget {
  const _EmailChangeTab({required this.authState});
  final AuthState authState;

  @override
  State<_EmailChangeTab> createState() => _EmailChangeTabState();
}

class _EmailChangeTabState extends State<_EmailChangeTab> {
  final _emailApi = EmailApi(ApiClient.instance);
  final _userApi = UserApi(ApiClient.instance);
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  bool _verified = false;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isEmailValid =>
      RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
          .hasMatch(_emailController.text);

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    try {
      await _emailApi.sendVerification(_emailController.text.trim());
      setState(() {
        _codeSent = true;
        _message = '인증번호가 발송되었습니다.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _verifying = true);
    try {
      await _emailApi.verify(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
      );
      setState(() {
        _verified = true;
        _message = '인증되었습니다.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _userApi.updateEmail(_emailController.text.trim());
      await widget.authState.refreshUserInfo();
      setState(() {
        _message = '이메일이 변경되었습니다.';
        _isError = false;
      });
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '새 이메일'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: _isEmailValid && !_sending ? _sendCode : null,
                  child: Text(_sending ? '전송 중...' : (_codeSent ? '재전송' : '인증번호 발송')),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: '인증번호'),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: _codeSent && !_verifying ? _verifyCode : null,
                  child: Text(_verifying ? '확인 중...' : (_verified ? '인증완료' : '인증번호 확인')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _message!,
                style: TextStyle(color: _isError ? Colors.red : Colors.green),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _verified && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('이메일 변경 저장'),
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeTab extends StatefulWidget {
  @override
  State<_PasswordChangeTab> createState() => _PasswordChangeTabState();
}

class _PasswordChangeTabState extends State<_PasswordChangeTab> {
  final _userApi = UserApi(ApiClient.instance);
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _saving = false;
  String? _message;
  bool _isError = false;

  static final _passwordPolicy = <_PasswordRule>[
    _PasswordRule('8~20자 이내', (pw) => pw.length >= 8 && pw.length <= 20),
    _PasswordRule('최소 1개의 대문자 포함', (pw) => RegExp('[A-Z]').hasMatch(pw)),
    _PasswordRule('최소 1개의 소문자 포함', (pw) => RegExp('[a-z]').hasMatch(pw)),
    _PasswordRule('최소 1개의 숫자 포함', (pw) => RegExp('[0-9]').hasMatch(pw)),
    _PasswordRule('최소 1개의 특수문자 포함', (pw) => RegExp(r'[\W_]').hasMatch(pw)),
  ];

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isNewPasswordValid =>
      _passwordPolicy.every((rule) => rule.test(_newPasswordController.text));

  bool get _isFormValid =>
      _currentPasswordController.text.isNotEmpty &&
      _isNewPasswordValid &&
      _newPasswordController.text == _confirmPasswordController.text;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _userApi.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      setState(() {
        _message = '비밀번호가 변경되었습니다.';
        _isError = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _currentPasswordController,
            decoration: const InputDecoration(labelText: '현재 비밀번호'),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: '새 비밀번호'),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _passwordPolicy
                  .map(
                    (rule) => Chip(
                      label: Text(
                        rule.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: rule.test(_newPasswordController.text)
                              ? Colors.lightGreenAccent
                              : Colors.white60,
                        ),
                      ),
                      backgroundColor: rule.test(_newPasswordController.text)
                          ? Colors.green.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  )
                  .toList(),
            ),
          ),
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _message!,
                style: TextStyle(color: _isError ? Colors.red : Colors.green),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _isFormValid && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('비밀번호 변경 저장'),
          ),
        ],
      ),
    );
  }
}

class _PasswordRule {
  _PasswordRule(this.label, this.test);
  final String label;
  final bool Function(String) test;
}
