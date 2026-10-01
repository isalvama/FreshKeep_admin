import 'package:equatable/equatable.dart';

/// One row of the users list.
class RegisteredUser extends Equatable {
  /// `users.id` — also the `creatorId` for the metrics endpoints.
  final String id;
  final String email;

  /// Nullable in the backend's `users` table.
  final String? username;

  /// UTC instants.
  final DateTime registeredAt;
  final DateTime? lastLoggedAt;

  const RegisteredUser({
    required this.id,
    required this.email,
    required this.username,
    required this.registeredAt,
    required this.lastLoggedAt,
  });

  @override
  List<Object?> get props => [id, email, username, registeredAt, lastLoggedAt];
}
