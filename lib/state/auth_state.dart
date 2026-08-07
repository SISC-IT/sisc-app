import 'package:flutter/foundation.dart';

import '../api/auth_api.dart';
import '../api/user_api.dart';
import '../core/api_client.dart';
import '../models/user_info.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthState extends ChangeNotifier {
  AuthState(this._apiClient)
    : _authApi = AuthApi(_apiClient),
      _userApi = UserApi(_apiClient);

  final ApiClient _apiClient;
  final AuthApi _authApi;
  final UserApi _userApi;

  AuthStatus status = AuthStatus.unknown;
  UserInfoResponse? userInfo;

  Future<void> restore() async {
    final hasSession = await _apiClient.hasSession();
    if (hasSession) {
      await _loadUserInfo();
    } else {
      status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<void> login({required String studentId, required String password}) async {
    await _authApi.login(studentId: studentId, password: password);
    await _loadUserInfo();
    notifyListeners();
  }

  Future<void> refreshUserInfo() async {
    await _loadUserInfo();
    notifyListeners();
  }

  Future<void> _loadUserInfo() async {
    try {
      userInfo = await _userApi.getDetails();
      status = AuthStatus.loggedIn;
    } catch (_) {
      userInfo = null;
      status = AuthStatus.loggedOut;
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
    markLoggedOut();
  }

  /// 서버에 세션 정리를 이미 완료한 뒤(예: 회원 탈퇴) 로컬 상태만 로그아웃으로 갱신한다.
  void markLoggedOut() {
    userInfo = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
