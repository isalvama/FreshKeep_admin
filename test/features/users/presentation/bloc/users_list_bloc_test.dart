import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_users_usecase.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/users_list_bloc.dart';
import 'package:fresh_keep_admin/features/users/presentation/users_list_query.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/selected_range.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/section_state.dart';

import '../../../../fakes/fake_users_repository.dart';

final _today = DateTime(2026, 10, 1, 9);
const _week = UsersListQuery(range: PresetRange(RangePreset.last7), page: 1);
const _monthPage2 = UsersListQuery(
  range: PresetRange(RangePreset.last30),
  page: 2,
);

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeUsersRepository repository;
  late UsersListBloc bloc;

  setUp(() {
    repository = FakeUsersRepository();
    bloc = UsersListBloc(
      getUsersUseCase: GetUsersUseCase(repository),
      today: () => _today,
    );
  });

  tearDown(() => bloc.close());

  test('starts on the default query, loading, without fetching', () {
    expect(bloc.state.query, kDefaultUsersListQuery);
    expect(bloc.state.users.status, SectionStatus.loading);
    expect(repository.listCalls, isEmpty);
  });

  test('a query change loads that page for the resolved range', () async {
    bloc.add(const UsersListQueryChanged(_monthPage2));
    await _settle();

    final (range, page) = repository.listCalls.single;
    expect(range.from, DateTime.utc(2026, 9, 2));
    expect(range.to, DateTime.utc(2026, 10, 1));
    expect(page, 2);
    expect(bloc.state.query, _monthPage2);
    expect(bloc.state.resolvedRange, range);
    expect(bloc.state.users.status, SectionStatus.loaded);
    expect(bloc.state.users.data!.firstIndex, 31);
  });

  test('marks the list loading while fetching', () async {
    repository.holdRequests = true;

    bloc.add(const UsersListQueryChanged(_week));
    await _settle();

    expect(bloc.state.query, _week);
    expect(bloc.state.users.status, SectionStatus.loading);

    repository.held.single.complete();
    await _settle();
    expect(bloc.state.users.status, SectionStatus.loaded);
  });

  test('an unchanged query is not refetched', () async {
    bloc.add(const UsersListQueryChanged(_week));
    await _settle();
    bloc.add(const UsersListQueryChanged(_week));
    await _settle();

    expect(repository.listCalls, hasLength(1));
  });

  test('a failure is kept in state with its message', () async {
    repository.usersPage = (_, _) => const Left(
      NetworkFailure('Could not reach the server. Please try again.'),
    );

    bloc.add(const UsersListQueryChanged(_week));
    await _settle();

    expect(bloc.state.users.status, SectionStatus.failure);
    expect(
      bloc.state.users.errorMessage,
      'Could not reach the server. Please try again.',
    );
  });

  test('Retry reloads the same query', () async {
    repository.usersPage = (_, _) =>
        const Left(ServerFailure('Something went wrong.'));
    bloc.add(const UsersListQueryChanged(_monthPage2));
    await _settle();

    repository.usersPage = (range, page) => Right(testUsersPage(page: page));
    bloc.add(const UsersListRetried());
    await _settle();

    expect(repository.listCalls, hasLength(2));
    expect(repository.listCalls.last.$2, 2);
    expect(bloc.state.users.status, SectionStatus.loaded);
  });

  test('a response for a query that is no longer current is dropped', () async {
    repository.holdRequests = true;

    bloc.add(const UsersListQueryChanged(_monthPage2));
    await _settle();
    bloc.add(const UsersListQueryChanged(_week));
    await _settle();

    // The week answer arrives first, then the stale page-2 one.
    repository.held[1].complete();
    await _settle();
    repository.held[0].complete();
    await _settle();

    expect(bloc.state.query, _week);
    expect(bloc.state.users.data!.page, 1);
  });
}
