import 'package:dio/dio.dart';

import '../../../../core/network/auth_interceptor.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSource(this.dio);

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await dio.post(kLoginPath, data: request.toJson());
    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}
