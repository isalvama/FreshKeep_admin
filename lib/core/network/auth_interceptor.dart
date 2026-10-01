import 'package:dio/dio.dart';

import '../constants/storage_keys.dart';
import '../storage/session_storage.dart';
import 'session_expired_notifier.dart';

const kLoginPath = '/api/v1/auth/login';

class AuthInterceptor extends Interceptor {
  final SessionStorage _sessionStorage;
  final SessionExpiredNotifier _sessionExpiredNotifier;

  AuthInterceptor({
    required SessionStorage sessionStorage,
    required SessionExpiredNotifier sessionExpiredNotifier,
  }) : _sessionStorage = sessionStorage,
       _sessionExpiredNotifier = sessionExpiredNotifier;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _sessionStorage.read(StorageKeys.jwt);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A 401 from login means wrong credentials, not an expired session.
    final isLogin = err.requestOptions.uri.path.endsWith(kLoginPath);
    if (err.response?.statusCode == 401 && !isLogin) {
      _sessionExpiredNotifier.notify();
    }
    handler.next(err);
  }
}
