import 'package:flutter/material.dart';

import '../api/auth_api.dart';
import '../api/email_api.dart';
import '../core/api_client.dart';
import '../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _authApi = AuthApi(ApiClient.instance);
  final _emailApi = EmailApi(ApiClient.instance);

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _generationController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _remarkController = TextEditingController();

  String _gender = 'MALE';
  bool _sendingCode = false;
  bool _verifyingCode = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  bool _submitting = false;
  String? _errorMessage;

  static final _passwordPolicy = <_PasswordRule>[
    _PasswordRule('8~20자 이내', (pw) => pw.length >= 8 && pw.length <= 20),
    _PasswordRule('최소 1개의 대문자 포함', (pw) => RegExp('[A-Z]').hasMatch(pw)),
    _PasswordRule('최소 1개의 소문자 포함', (pw) => RegExp('[a-z]').hasMatch(pw)),
    _PasswordRule('최소 1개의 숫자 포함', (pw) => RegExp('[0-9]').hasMatch(pw)),
    _PasswordRule('최소 1개의 특수문자 포함', (pw) => RegExp(r'[\W_]').hasMatch(pw)),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _verificationCodeController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _generationController.dispose();
    _teamNameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  bool get _isEmailValid =>
      RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
          .hasMatch(_emailController.text);

  bool get _isPhoneValid =>
      RegExp(r'^010-\d{3,4}-\d{4}$').hasMatch(_phoneController.text);

  bool get _isStudentIdValid => RegExp(r'^\d{8}$').hasMatch(_studentIdController.text);

  bool get _isPasswordValid =>
      _passwordPolicy.every((rule) => rule.test(_passwordController.text));

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _isStudentIdValid &&
      _isPasswordValid &&
      _passwordController.text == _confirmPasswordController.text &&
      _isEmailValid &&
      _codeVerified &&
      _isPhoneValid &&
      _generationController.text.trim().isNotEmpty &&
      _collegeController.text.trim().isNotEmpty &&
      _departmentController.text.trim().isNotEmpty &&
      _teamNameController.text.trim().isNotEmpty;

  void _formatPhoneInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    String formatted;
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      formatted =
          '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, digits.length > 11 ? 11 : digits.length)}';
    }
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  Future<void> _sendCode() async {
    setState(() => _sendingCode = true);
    try {
      await _emailApi.sendVerification(_emailController.text.trim());
      setState(() {
        _codeSent = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _verifyingCode = true);
    try {
      await _emailApi.verify(
        email: _emailController.text.trim(),
        code: _verificationCodeController.text.trim(),
      );
      setState(() {
        _codeVerified = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _authApi.signup(
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        college: _collegeController.text.trim(),
        department: _departmentController.text.trim(),
        generation: int.parse(_generationController.text.trim()),
        teamName: _teamNameController.text.trim(),
        remark: _remarkController.text.trim().isEmpty
            ? null
            : _remarkController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('회장 승인 후 이용하실 수 있습니다.'),
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
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(labelText: '학번 (8자리)'),
              keyboardType: TextInputType.number,
              maxLength: 8,
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                            color: rule.test(_passwordController.text)
                                ? Colors.lightGreenAccent
                                : Colors.white60,
                          ),
                        ),
                        backgroundColor: rule.test(_passwordController.text)
                            ? Colors.green.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    )
                    .toList(),
              ),
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: '이메일'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: _isEmailValid && !_sendingCode ? _sendCode : null,
                    child: Text(_sendingCode ? '전송 중...' : (_codeSent ? '재전송' : '인증번호 발송')),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _verificationCodeController,
                    decoration: const InputDecoration(labelText: '인증번호'),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: _codeSent && !_verifyingCode ? _verifyCode : null,
                    child: Text(_verifyingCode
                        ? '확인 중...'
                        : (_codeVerified ? '인증완료' : '인증번호 확인')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: '전화번호 (010-1234-5678)'),
              keyboardType: TextInputType.phone,
              onChanged: _formatPhoneInput,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('성별'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'MALE',
                  groupValue: _gender,
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                const Text('남성'),
                Radio<String>(
                  value: 'FEMALE',
                  groupValue: _gender,
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                const Text('여성'),
              ],
            ),
            TextField(
              controller: _collegeController,
              decoration: const InputDecoration(labelText: '단과대학'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: '학과'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _generationController,
              decoration: const InputDecoration(labelText: '기수'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(labelText: '활동팀'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(labelText: '특이사항 (선택)'),
            ),
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
              onPressed: _isFormValid && !_submitting ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRule {
  _PasswordRule(this.label, this.test);
  final String label;
  final bool Function(String) test;
}
