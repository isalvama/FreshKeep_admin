part of 'users_list_bloc.dart';

class UsersListState extends Equatable {
  final UsersListQuery query;

  /// [query]'s range resolved against "today" when it was last loaded.
  final DateRange resolvedRange;
  final SectionState<UsersPage> users;

  const UsersListState({
    required this.query,
    required this.resolvedRange,
    this.users = const SectionState.loading(),
  });

  UsersListState copyWith({SectionState<UsersPage>? users}) => UsersListState(
    query: query,
    resolvedRange: resolvedRange,
    users: users ?? this.users,
  );

  @override
  List<Object?> get props => [query, resolvedRange, users];
}
