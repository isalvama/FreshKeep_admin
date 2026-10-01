import '../../domain/entities/registered_user.dart';
import '../../domain/entities/users_page.dart';
import '../../../../core/network/json_readers.dart';

class RegisteredUserModel extends RegisteredUser {
  const RegisteredUserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.registeredAt,
    required super.lastLoggedAt,
  });

  /// `{id, email, username, registeredAt, lastLoggedAt}`.
  factory RegisteredUserModel.fromJson(Map<String, dynamic> json) {
    return RegisteredUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      registeredAt: readInstant(json['registeredAt']),
      lastLoggedAt: readOptionalInstant(json['lastLoggedAt']),
    );
  }
}

class UsersPageModel extends UsersPage {
  const UsersPageModel({
    required super.users,
    required super.page,
    required super.size,
    required super.totalElements,
    required super.totalPages,
  });

  /// `{content, page, size, totalElements, totalPages}`.
  factory UsersPageModel.fromJson(Map<String, dynamic> json) {
    return UsersPageModel(
      users: [
        for (final user in json['content'] as List)
          RegisteredUserModel.fromJson(user as Map<String, dynamic>),
      ],
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );
  }
}
