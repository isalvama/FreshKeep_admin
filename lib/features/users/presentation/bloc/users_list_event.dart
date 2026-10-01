part of 'users_list_bloc.dart';

sealed class UsersListEvent {
  const UsersListEvent();
}

/// The URL's range or page changed (or the page opened).
final class UsersListQueryChanged extends UsersListEvent {
  final UsersListQuery query;

  const UsersListQueryChanged(this.query);
}

/// The Retry button: reloads the current query.
final class UsersListRetried extends UsersListEvent {
  const UsersListRetried();
}
