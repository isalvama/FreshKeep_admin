import 'dart:math';

import 'package:equatable/equatable.dart';

import 'registered_user.dart';

/// One page of the users list, as the backend pages it (1-based).
class UsersPage extends Equatable {
  final List<RegisteredUser> users;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const UsersPage({
    required this.users,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  /// 1-based position of the first row in the whole list ("31" in
  /// "31–60 of 214"); 0 when the page is empty.
  int get firstIndex => users.isEmpty ? 0 : (page - 1) * size + 1;

  /// 1-based position of the last row ("60" in "31–60 of 214"); 0 when the
  /// page is empty.
  int get lastIndex =>
      users.isEmpty ? 0 : min(firstIndex + users.length - 1, totalElements);

  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  @override
  List<Object?> get props => [users, page, size, totalElements, totalPages];
}
