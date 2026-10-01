import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/shell/presentation/shell_destination.dart';

void main() {
  final users = shellDestinations.firstWhere((d) => d.path == '/users');

  test('matches the section itself and pages under it', () {
    expect(users.matches('/users'), isTrue);
    expect(users.matches('/users/abc'), isTrue);
    expect(users.matches('/users/abc/more'), isTrue);
  });

  test('does not match look-alikes, a bare trailing slash, or others', () {
    for (final path in ['/userszzz', '/user', '/users/', '/nope/users', '/']) {
      expect(users.matches(path), isFalse, reason: path);
    }
  });

  test('each path belongs to at most one section', () {
    for (final path in ['/dashboard', '/users/x', '/products', '/receipts/y']) {
      expect(
        shellDestinations.where((d) => d.matches(path)),
        hasLength(1),
        reason: path,
      );
    }
  });
}
