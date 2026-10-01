import 'package:dio/dio.dart';

import '../storage/session_storage.dart';
import 'auth_interceptor.dart';
import 'session_expired_notifier.dart';

class DioClient {
  final Dio dio;

  DioClient({
    required String baseUrl,
    required SessionStorage sessionStorage,
    required SessionExpiredNotifier sessionExpiredNotifier,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           headers: {'Content-Type': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      AuthInterceptor(
        sessionStorage: sessionStorage,
        sessionExpiredNotifier: sessionExpiredNotifier,
      ),
    );
  }
}
