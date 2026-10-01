import 'package:equatable/equatable.dart';

class UserDetails extends Equatable {
  final String id;
  final String email;
  final String? username;

  /// UTC instants.
  final DateTime registeredAt;
  final DateTime? lastLoggedAt;

  /// Raw backend roles, e.g. `USER`, `ADMIN`.
  final List<String> roles;
  final List<UserSpace> spaces;

  /// Newest first, as the backend sends them. Includes unconfirmed drafts.
  final List<UserReceipt> receipts;

  const UserDetails({
    required this.id,
    required this.email,
    required this.username,
    required this.registeredAt,
    required this.lastLoggedAt,
    required this.roles,
    required this.spaces,
    required this.receipts,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    registeredAt,
    lastLoggedAt,
    roles,
    spaces,
    receipts,
  ];
}

/// A space the user participates in.
class UserSpace extends Equatable {
  final String id;
  final String name;

  const UserSpace({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// A shopping receipt the user created.
class UserReceipt extends Equatable {
  final String id;

  /// UTC instant.
  final DateTime createdAt;

  /// A calendar day.
  final DateTime purchaseDate;
  final String? storeName;

  const UserReceipt({
    required this.id,
    required this.createdAt,
    required this.purchaseDate,
    required this.storeName,
  });

  @override
  List<Object?> get props => [id, createdAt, purchaseDate, storeName];
}
