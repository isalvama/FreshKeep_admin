import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_user_details_usecase.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/user_detail_bloc.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_products_added_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_receipts_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/section_state.dart';

import '../../../../fakes/fake_dashboard_repository.dart';
import '../../../../fakes/fake_users_repository.dart';

final _today = DateTime(2026, 10, 1, 9);

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeUsersRepository users;
  late FakeDashboardRepository metrics;
  late UserDetailBloc bloc;

  setUp(() {
    users = FakeUsersRepository();
    metrics = FakeDashboardRepository()
      ..products = Right([
        DailyCount(date: DateTime.utc(2026, 9, 30), count: 4),
      ]);
    bloc = UserDetailBloc(
      getUserDetailsUseCase: GetUserDetailsUseCase(users),
      getProductsAddedUseCase: GetProductsAddedUseCase(metrics),
      getReceiptsUseCase: GetReceiptsUseCase(metrics),
      today: () => _today,
    );
  });

  tearDown(() => bloc.close());

  test('starts with no user and fetches nothing', () {
    expect(bloc.state.userId, '');
    expect(users.detailCalls, isEmpty);
    expect(metrics.calls, isEmpty);
  });

  group('UserDetailRequested', () {
    test('loads the details and both activity series for the last 30 days, '
        'with creatorId', () async {
      bloc.add(const UserDetailRequested('user-1'));
      await _settle();

      expect(users.detailCalls, ['user-1']);
      expect(metrics.calls.map((c) => c.$1).toSet(), {'products', 'receipts'});
      expect(metrics.creatorIds, ['user-1', 'user-1']);
      for (final (_, range) in metrics.calls) {
        expect(range!.from, DateTime.utc(2026, 9, 2));
        expect(range.to, DateTime.utc(2026, 10, 1));
      }

      final state = bloc.state;
      expect(state.userId, 'user-1');
      expect(state.details.status, SectionStatus.loaded);
      expect(state.details.data!.email, 'user1@example.com');
      expect(state.userNotFound, isFalse);
      // Zero-filled through the shared use cases.
      expect(state.productsActivity.data, hasLength(30));
      expect(state.receiptsActivity.data, hasLength(30));
    });

    test('the same user is not requested again', () async {
      bloc.add(const UserDetailRequested('user-1'));
      await _settle();
      bloc.add(const UserDetailRequested('user-1'));
      await _settle();

      expect(users.detailCalls, hasLength(1));
    });

    test('a 400 marks the user as not found', () async {
      users.details = const Left(
        ValidationFailure('User with id nope does not exist.'),
      );

      bloc.add(const UserDetailRequested('nope'));
      await _settle();

      expect(bloc.state.userNotFound, isTrue);
      expect(bloc.state.details.status, SectionStatus.failure);
    });

    test('other failures are not "not found"', () async {
      users.details = const Left(
        NetworkFailure('Could not reach the server. Please try again.'),
      );

      bloc.add(const UserDetailRequested('user-1'));
      await _settle();

      expect(bloc.state.userNotFound, isFalse);
      expect(
        bloc.state.details.errorMessage,
        'Could not reach the server. Please try again.',
      );
    });

    test('one failing section leaves the others loaded', () async {
      metrics.receipts = const Left(ServerFailure('Something went wrong.'));

      bloc.add(const UserDetailRequested('user-1'));
      await _settle();

      expect(bloc.state.receiptsActivity.status, SectionStatus.failure);
      expect(bloc.state.details.status, SectionStatus.loaded);
      expect(bloc.state.productsActivity.status, SectionStatus.loaded);
    });

    test('a response for a user no longer shown is dropped', () async {
      users.holdDetails = true;

      bloc.add(const UserDetailRequested('user-1'));
      await _settle();
      bloc.add(const UserDetailRequested('user-2'));
      await _settle();

      users.details = Right(testUserDetails(id: 'user-2'));
      users.heldDetails[1].complete();
      await _settle();
      // user-1's late answer must not replace user-2's.
      users.details = Right(testUserDetails(id: 'user-1'));
      users.heldDetails[0].complete();
      await _settle();

      expect(bloc.state.userId, 'user-2');
      expect(bloc.state.details.data!.id, 'user-2');
    });
  });

  group('UserDetailSectionRetried', () {
    test('reloads only the details, clearing a previous "not found"', () async {
      users.details = const Left(ValidationFailure('nope'));
      bloc.add(const UserDetailRequested('user-1'));
      await _settle();
      expect(bloc.state.userNotFound, isTrue);

      users.details = Right(testUserDetails());
      bloc.add(const UserDetailSectionRetried(UserDetailSection.details));
      await _settle();

      expect(bloc.state.userNotFound, isFalse);
      expect(bloc.state.details.status, SectionStatus.loaded);
      expect(users.detailCalls, hasLength(2));
      expect(metrics.callsTo('products'), 1);
      expect(metrics.callsTo('receipts'), 1);
    });

    test('reloads only one activity series, with creatorId', () async {
      metrics.products = const Left(ServerFailure('Something went wrong.'));
      bloc.add(const UserDetailRequested('user-1'));
      await _settle();

      metrics.products = const Right([]);
      bloc.add(
        const UserDetailSectionRetried(UserDetailSection.productsActivity),
      );
      await _settle();

      expect(bloc.state.productsActivity.status, SectionStatus.loaded);
      expect(metrics.callsTo('products'), 2);
      expect(metrics.callsTo('receipts'), 1);
      expect(users.detailCalls, hasLength(1));
      expect(metrics.creatorIds.last, 'user-1');
    });
  });
}
