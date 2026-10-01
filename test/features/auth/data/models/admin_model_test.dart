import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/auth/data/models/admin_model.dart';

import '../../../../fakes/jwt_factory.dart';

void main() {
  group('AdminModel.fromJwt', () {
    test('reads accountId, adminId and email (sub) from the claims', () {
      final admin = AdminModel.fromJwt(buildJwt());

      expect(admin.accountId, kTestAccountId);
      expect(admin.adminId, kTestAdminId);
      expect(admin.email, kTestEmail);
    });

    test('throws FormatException when adminId is missing', () {
      expect(
        () => AdminModel.fromJwt(buildJwt(adminId: null)),
        throwsFormatException,
      );
    });

    test('throws FormatException for an undecodable token', () {
      expect(() => AdminModel.fromJwt('not-a-jwt'), throwsFormatException);
    });
  });

  group('AdminModel.hasAdminRole', () {
    test('is true when roles contain ROLE_ADMIN', () {
      expect(
        AdminModel.hasAdminRole(buildJwt(roles: ['ROLE_USER', 'ROLE_ADMIN'])),
        isTrue,
      );
    });

    test('is false for USER-only and unprefixed roles', () {
      expect(AdminModel.hasAdminRole(buildJwt(roles: ['ROLE_USER'])), isFalse);
      expect(AdminModel.hasAdminRole(buildJwt(roles: ['ADMIN'])), isFalse);
    });
  });
}
