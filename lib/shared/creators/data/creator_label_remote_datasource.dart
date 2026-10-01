import 'package:dio/dio.dart';

import '../../../core/network/admin_api_paths.dart';

class CreatorLabelRemoteDataSource {
  final Dio dio;

  const CreatorLabelRemoteDataSource(this.dio);

  /// Reads only `email` from the user's details. The id is encoded so it can
  /// only ever be one path segment.
  Future<String> getUserEmail(String userId) async {
    final response = await dio.get(
      '$kAdminUsersApiPath/${Uri.encodeComponent(userId)}',
    );
    return (response.data as Map<String, dynamic>)['email'] as String;
  }
}
