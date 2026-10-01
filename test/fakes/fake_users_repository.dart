import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/users/domain/entities/registered_user.dart';
import 'package:fresh_keep_admin/features/users/domain/entities/user_details.dart';
import 'package:fresh_keep_admin/features/users/domain/entities/users_page.dart';
import 'package:fresh_keep_admin/features/users/domain/repositories/users_repository.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/date_range.dart';

/// Answers from settable results and records calls.
///
/// [usersPage] builds the answer for each list call (by default a full page
/// of [kUsersPageSize] users out of 214). When [holdRequests] is true, list
/// calls wait in [held] until a test completes them, in any order.
class FakeUsersRepository implements UsersRepository {
  Either<AdminFailure, UsersPage> Function(DateRange range, int page)
  usersPage = (range, page) => Right(testUsersPage(page: page));
  Either<AdminFailure, UserDetails> details = Right(testUserDetails());

  bool holdRequests = false;
  final held = <Completer<void>>[];

  /// Like [holdRequests], for detail calls; the answer is read on release,
  /// so a test can change [details] before completing a held call.
  bool holdDetails = false;
  final heldDetails = <Completer<void>>[];

  final List<(DateRange, int)> listCalls = [];
  final List<String> detailCalls = [];

  @override
  Future<Either<AdminFailure, UsersPage>> getUsers(
    DateRange registeredBetween, {
    required int page,
  }) async {
    listCalls.add((registeredBetween, page));
    if (holdRequests) {
      final completer = Completer<void>();
      held.add(completer);
      await completer.future;
    }
    return usersPage(registeredBetween, page);
  }

  @override
  Future<Either<AdminFailure, UserDetails>> getUser(String userId) async {
    detailCalls.add(userId);
    if (holdDetails) {
      final completer = Completer<void>();
      heldDetails.add(completer);
      await completer.future;
    }
    return details;
  }
}

/// Page [page] of [total] users, [kUsersPageSize] per page, newest first.
UsersPage testUsersPage({int page = 1, int total = 214}) {
  final totalPages = (total / kUsersPageSize).ceil();
  final first = (page - 1) * kUsersPageSize;
  final count = (total - first).clamp(0, kUsersPageSize);
  return UsersPage(
    users: [
      for (var i = first; i < first + count; i++)
        RegisteredUser(
          id: 'user-$i',
          email: 'user$i@example.com',
          username: i == 0 ? null : 'user$i',
          registeredAt: DateTime.utc(
            2026,
            9,
            30,
            12,
          ).subtract(Duration(hours: i)),
          lastLoggedAt: i.isEven ? DateTime.utc(2026, 10, 1, 8) : null,
        ),
    ],
    page: page,
    size: kUsersPageSize,
    totalElements: count == 0 ? 0 : total,
    totalPages: count == 0 ? 0 : totalPages,
  );
}

UserDetails testUserDetails({
  String id = 'user-1',
  List<UserSpace>? spaces,
  List<UserReceipt>? receipts,
}) => UserDetails(
  id: id,
  email: 'user1@example.com',
  username: 'user1',
  registeredAt: DateTime.utc(2026, 9, 14, 12, 32),
  lastLoggedAt: DateTime.utc(2026, 9, 20, 8, 30),
  roles: const ['USER', 'ADMIN'],
  spaces: spaces ?? const [UserSpace(id: 's-1', name: 'Kitchen')],
  receipts:
      receipts ??
      [
        UserReceipt(
          id: 'r-2',
          createdAt: DateTime.utc(2026, 9, 28, 18, 5),
          purchaseDate: DateTime.utc(2026, 9, 28),
          storeName: 'SuperMart',
        ),
        UserReceipt(
          id: 'r-1',
          createdAt: DateTime.utc(2026, 9, 15, 10),
          purchaseDate: DateTime.utc(2026, 9, 14),
          storeName: null,
        ),
      ],
);
