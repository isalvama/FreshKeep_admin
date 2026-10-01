import '../../domain/entities/user_details.dart';
import 'json_readers.dart';

class UserDetailsModel extends UserDetails {
  const UserDetailsModel({
    required super.id,
    required super.email,
    required super.username,
    required super.registeredAt,
    required super.lastLoggedAt,
    required super.roles,
    required super.spaces,
    required super.receipts,
  });

  /// `{id, email, username, registeredAt, lastLoggedAt, roles,
  /// spaces: [{id, name}], receipts: [{id, createdAt, purchaseDate, storeName}]}`.
  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      registeredAt: readInstant(json['registeredAt']),
      lastLoggedAt: readOptionalInstant(json['lastLoggedAt']),
      roles: [for (final role in json['roles'] as List) role as String],
      spaces: [
        for (final space in json['spaces'] as List)
          UserSpace(
            id: (space as Map<String, dynamic>)['id'] as String,
            name: space['name'] as String,
          ),
      ],
      receipts: [
        for (final receipt in json['receipts'] as List)
          UserReceipt(
            id: (receipt as Map<String, dynamic>)['id'] as String,
            createdAt: readInstant(receipt['createdAt']),
            purchaseDate: readCalendarDay(receipt['purchaseDate']),
            storeName: receipt['storeName'] as String?,
          ),
      ],
    );
  }
}
