import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/receipts/domain/usecases/get_receipts_list_usecase.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/bloc/receipts_list_bloc.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/receipts_list_query.dart';
import 'package:fresh_keep_admin/shared/creators/domain/get_creator_label_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/selected_range.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/section_state.dart';

import '../../../../fakes/fake_receipts_repository.dart';

final _today = DateTime(2026, 10, 1, 9);
const _week = ReceiptsListQuery(range: PresetRange(RangePreset.last7));
const _byCreator = ReceiptsListQuery(creatorId: kTestReceiptCreatorId);

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeReceiptsRepository repository;
  late ReceiptsListBloc bloc;

  setUp(() {
    repository = FakeReceiptsRepository();
    bloc = ReceiptsListBloc(
      getReceiptsListUseCase: GetReceiptsListUseCase(repository),
      getCreatorLabelUseCase: GetCreatorLabelUseCase(repository),
      today: () => _today,
    );
  });

  tearDown(() => bloc.close());

  test('starts on the default query, loading, without fetching', () {
    expect(bloc.state.query, kDefaultReceiptsListQuery);
    expect(bloc.state.receipts.status, SectionStatus.loading);
    expect(bloc.state.creatorLabel, isNull);
    expect(repository.listCalls, isEmpty);
  });

  test('loads the page for the resolved range', () async {
    bloc.add(ReceiptsListRequested(_week.withPage(2)));
    await _settle();

    final (range, creatorId, page) = repository.listCalls.single;
    expect(range.from, DateTime.utc(2026, 9, 25));
    expect(range.to, DateTime.utc(2026, 10, 1));
    expect(creatorId, isNull);
    expect(page, 2);
    expect(bloc.state.resolvedRange, range);
    expect(bloc.state.receipts.status, SectionStatus.loaded);
    expect(bloc.state.receipts.data!.firstIndex, 31);
  });

  test('without a creator filter, no chip is looked up', () async {
    bloc.add(const ReceiptsListRequested(_week));
    await _settle();

    expect(repository.creatorCalls, isEmpty);
    expect(bloc.state.creatorLabel, isNull);
  });

  test('the page and the creator label load in parallel', () async {
    repository
      ..holdReceipts = true
      ..holdLabels = true;

    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();

    expect(repository.listCalls.single.$2, kTestReceiptCreatorId);
    expect(repository.creatorCalls, [kTestReceiptCreatorId]);
    expect(bloc.state.receipts.status, SectionStatus.loading);
    expect(bloc.state.creatorLabel!.status, SectionStatus.loading);

    for (final completer in [
      ...repository.heldLabels,
      ...repository.heldReceipts,
    ]) {
      completer.complete();
    }
    await _settle();

    expect(bloc.state.receipts.status, SectionStatus.loaded);
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('a chip that fails does not block the page', () async {
    repository.creatorEmail = const Left(
      ServerFailure('Something went wrong.'),
    );

    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();

    expect(bloc.state.receipts.status, SectionStatus.loaded);
    expect(bloc.state.creatorLabel!.status, SectionStatus.failure);
  });

  test('a page failure keeps its message', () async {
    repository.receiptsPage = (_, _, _) => const Left(
      NetworkFailure('Could not reach the server. Please try again.'),
    );

    bloc.add(const ReceiptsListRequested(_week));
    await _settle();

    expect(bloc.state.receipts.status, SectionStatus.failure);
    expect(
      bloc.state.receipts.errorMessage,
      'Could not reach the server. Please try again.',
    );
  });

  test('paging or a new range does not look the creator up again', () async {
    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();
    bloc.add(ReceiptsListRequested(_byCreator.withPage(2)));
    await _settle();
    bloc.add(
      ReceiptsListRequested(
        _byCreator.withRange(const PresetRange(RangePreset.last90)),
      ),
    );
    await _settle();

    expect(repository.listCalls, hasLength(3));
    expect(repository.creatorCalls, hasLength(1));
  });

  test('a creator that comes back (✕ then Back) reuses its label', () async {
    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();
    bloc.add(const ReceiptsListRequested(_week));
    await _settle();
    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();

    expect(repository.creatorCalls, hasLength(1));
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('a lookup still running is not started again by paging', () async {
    repository.holdLabels = true;

    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();
    bloc.add(ReceiptsListRequested(_byCreator.withPage(2)));
    await _settle();

    expect(repository.creatorCalls, hasLength(1));

    repository.heldLabels.single.complete();
    await _settle();
    expect(bloc.state.query.page, 2);
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('a failed label is retried by Retry, not by paging', () async {
    repository.creatorEmail = const Left(
      ServerFailure('Something went wrong.'),
    );
    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();
    bloc.add(ReceiptsListRequested(_byCreator.withPage(2)));
    await _settle();
    expect(repository.creatorCalls, hasLength(1));

    repository.creatorEmail = const Right('alice@example.com');
    bloc.add(const ReceiptsListRetried());
    await _settle();

    expect(repository.creatorCalls, hasLength(2));
    expect(repository.listCalls.last.$3, 2);
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('Retry reloads the same page', () async {
    repository.receiptsPage = (_, _, _) =>
        const Left(ServerFailure('Something went wrong.'));
    bloc.add(ReceiptsListRequested(_week.withPage(3)));
    await _settle();

    repository.receiptsPage = (_, _, page) =>
        Right(testReceiptsPage(page: page));
    bloc.add(const ReceiptsListRetried());
    await _settle();

    expect(repository.listCalls, hasLength(2));
    expect(repository.listCalls.last.$3, 3);
    expect(bloc.state.receipts.status, SectionStatus.loaded);
  });

  test('an unchanged query is not refetched', () async {
    bloc.add(const ReceiptsListRequested(_week));
    await _settle();
    bloc.add(const ReceiptsListRequested(_week));
    await _settle();

    expect(repository.listCalls, hasLength(1));
  });

  test('a page answer for a query no longer shown is dropped', () async {
    repository.holdReceipts = true;

    bloc.add(ReceiptsListRequested(_week.withPage(2)));
    await _settle();
    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();

    repository.heldReceipts[1].complete();
    await _settle();
    repository.heldReceipts[0].complete();
    await _settle();

    expect(bloc.state.query, _byCreator);
    expect(bloc.state.receipts.data!.page, 1);
  });

  test('a stale answer for the same query (Retry while loading) is '
      'dropped', () async {
    repository.holdReceipts = true;
    bloc.add(const ReceiptsListRequested(_week));
    await _settle();
    bloc.add(const ReceiptsListRetried());
    await _settle();

    repository.heldReceipts[1].complete();
    await _settle();
    repository.receiptsPage = (_, _, _) =>
        const Left(ServerFailure('Something went wrong.'));
    repository.heldReceipts[0].complete();
    await _settle();

    expect(bloc.state.receipts.status, SectionStatus.loaded);
  });

  test('a label answer for a creator no longer filtered is dropped', () async {
    repository.holdLabels = true;

    bloc.add(const ReceiptsListRequested(_byCreator));
    await _settle();
    bloc.add(const ReceiptsListRequested(_week));
    await _settle();

    repository.heldLabels.single.complete();
    await _settle();

    expect(bloc.state.query, _week);
    expect(bloc.state.creatorLabel, isNull);
  });
}
