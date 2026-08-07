import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';

/// 쿠키 기반 JWT 세션(access/refresh)을 유지하는 Dio 클라이언트.
/// 웹 프론트(frontend/src/utils/axios.js)와 동일하게 401 발생 시
/// /api/auth/reissue 를 호출해 쿠키를 갱신하고 원 요청을 재시도한다.
class ApiClient {
  ApiClient._(this.dio, this.cookieJar);

  final Dio dio;
  final CookieJar cookieJar;

  static ApiClient? _instance;

  static ApiClient get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('ApiClient.init()을 먼저 호출해야 합니다.');
    }
    return instance;
  }

  static Future<ApiClient> init() async {
    final supportDir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${supportDir.path}/.cookies/'),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(_ReissueInterceptor(dio));

    final client = ApiClient._(dio, cookieJar);
    _instance = client;
    return client;
  }

  /// 저장된 refresh 쿠키가 있는지로 로그인 상태를 낙관적으로 판단한다.
  Future<bool> hasSession() async {
    final cookies = await cookieJar.loadForRequest(Uri.parse(apiBaseUrl));
    return cookies.any((c) => c.name == 'refresh');
  }

  Future<void> clearSession() async {
    await cookieJar.deleteAll();
  }
}

class _ReissueInterceptor extends Interceptor {
  _ReissueInterceptor(this._dio);

  final Dio _dio;
  bool _isReissuing = false;

  static const _reissuePath = '/api/auth/reissue';
  static const _retriedKey = 'retried_after_reissue';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final isAuthEndpoint = requestOptions.path == _reissuePath;
    final alreadyRetried = requestOptions.extra[_retriedKey] == true;

    if (err.response?.statusCode == 401 && !isAuthEndpoint && !alreadyRetried) {
      final retried = await _tryReissueAndRetry(requestOptions);
      if (retried != null) {
        handler.resolve(retried);
        return;
      }
    }
    handler.next(err);
  }

  Future<Response?> _tryReissueAndRetry(RequestOptions original) async {
    if (_isReissuing) return null;
    _isReissuing = true;
    try {
      final reissueResponse = await _dio.post<void>(_reissuePath);
      if (reissueResponse.statusCode != 200) return null;

      final retryOptions = original.copyWith(
        extra: {...original.extra, _retriedKey: true},
      );
      return await _dio.fetch(retryOptions);
    } catch (_) {
      return null;
    } finally {
      _isReissuing = false;
    }
  }
}
