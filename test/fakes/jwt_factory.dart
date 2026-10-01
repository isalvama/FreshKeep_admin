import 'dart:convert';

const kTestAccountId = '6f1c2e8a-0000-4000-8000-000000000001';
const kTestAdminId = '6f1c2e8a-0000-4000-8000-000000000002';
const kTestEmail = 'admin@freshkeep.com';

/// Builds an unsigned JWT shaped like the backend's (see
/// `JwtTokenGeneratorAdapter`). `jwt_decoder` never verifies signatures, so
/// the signature segment is a placeholder.
///
/// `exp` is in seconds (a standard NumericDate), as jjwt writes it. Null
/// claims are omitted, as jjwt does.
String buildJwt({
  List<String> roles = const ['ROLE_ADMIN'],
  String? accountId = kTestAccountId,
  String? adminId = kTestAdminId,
  String? userId,
  String? sub = kTestEmail,
  Duration expiresIn = const Duration(hours: 1),
  bool includeExp = true,
}) {
  final now = DateTime.now();
  final claims = <String, Object?>{
    'roles': roles,
    'accountId': accountId,
    'sub': sub,
    'userId': userId,
    'adminId': adminId,
    'iat': now.millisecondsSinceEpoch ~/ 1000,
    if (includeExp) 'exp': now.add(expiresIn).millisecondsSinceEpoch ~/ 1000,
  }..removeWhere((_, value) => value == null);

  String encode(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  return '${encode({'alg': 'HS256'})}.${encode(claims)}.signature';
}
