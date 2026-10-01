import 'package:dio/dio.dart';

import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../../../shared/metrics/domain/utils/calendar_day.dart';
import '../../domain/repositories/users_repository.dart';
import '../models/user_details_model.dart';
import '../models/users_page_model.dart';

const kUsersPath = '/api/v1/admin/users';

class UsersRemoteDataSource {
  final Dio dio;

  const UsersRemoteDataSource(this.dio);

  Future<UsersPageModel> getUsers(
    DateRange registeredBetween, {
    required int page,
  }) async {
    final response = await dio.get(
      kUsersPath,
      queryParameters: {
        'from': isoDate(registeredBetween.from),
        'to': isoDate(registeredBetween.to),
        'page': page,
        'size': kUsersPageSize,
      },
    );
    return UsersPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserDetailsModel> getUser(String userId) async {
    // The id comes from the URL bar: encode it so it can only ever be one
    // path segment (e.g. "../products" can't reach another endpoint).
    final response = await dio.get(
      '$kUsersPath/${Uri.encodeComponent(userId)}',
    );
    return UserDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
