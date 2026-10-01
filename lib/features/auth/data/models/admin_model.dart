import 'package:jwt_decoder/jwt_decoder.dart';

import '../../domain/entities/admin.dart';

const kAdminRole = 'ROLE_ADMIN';

class AdminModel extends Admin {
  const AdminModel({
    required super.accountId,
    required super.adminId,
    required super.email,
  });

  /// Reads the admin from the token's claims. Throws [FormatException] when
  /// the token can't be decoded or a claim is missing (e.g. a USER-only token
  /// has no `adminId`).
  factory AdminModel.fromJwt(String jwt) {
    final claims = JwtDecoder.decode(jwt);
    return AdminModel(
      accountId: _requireString(claims, 'accountId'),
      adminId: _requireString(claims, 'adminId'),
      email: _requireString(claims, 'sub'),
    );
  }

  /// Whether the token's `roles` claim contains `ROLE_ADMIN` (the backend
  /// prefixes roles with `ROLE_`). Throws [FormatException] if undecodable.
  static bool hasAdminRole(String jwt) {
    final roles = JwtDecoder.decode(jwt)['roles'];
    return roles is List && roles.contains(kAdminRole);
  }

  static String _requireString(Map<String, dynamic> claims, String name) {
    final value = claims[name];
    if (value is! String || value.isEmpty) {
      throw FormatException('JWT is missing the "$name" claim');
    }
    return value;
  }
}
