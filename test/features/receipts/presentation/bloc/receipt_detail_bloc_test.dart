import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/receipts/domain/usecases/get_receipt_details_usecase.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/bloc/receipt_detail_bloc.dart';

import '../../../../fakes/fake_receipts_repository.dart';

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeReceiptsRepository repository;
  late ReceiptDetailBloc bloc;

  setUp(() {
    repository = FakeReceiptsRepository();
    bloc = ReceiptDetailBloc(
      getReceiptDetailsUseCase: GetReceiptDetailsUseCase(repository),
    );
  });

  tearDown(() => bloc.close());

  test('starts loading, without fetching', () {
    expect(bloc.state, const ReceiptDetailState());
    expect(repository.detailCalls, isEmpty);
  });

  test('loads the requested receipt', () async {
    repository.holdDetails = true;

    bloc.add(const ReceiptDetailRequested('r-1'));
    await _settle();
    expect(bloc.state.receiptId, 'r-1');
    expect(bloc.state.status, ReceiptDetailStatus.loading);

    repository.heldDetails.single.complete();
    await _settle();
    expect(bloc.state.status, ReceiptDetailStatus.loaded);
    expect(bloc.state.receipt, testReceiptDetails());
  });

  test('a 400 (unknown or malformed id) is not found', () async {
    repository.details = const Left(ValidationFailure('No such receipt.'));

    bloc.add(const ReceiptDetailRequested('x'));
    await _settle();

    expect(bloc.state.status, ReceiptDetailStatus.notFound);
  });

  test('other failures keep their message, and Retry reloads', () async {
    repository.details = const Left(ServerFailure('Something went wrong.'));
    bloc.add(const ReceiptDetailRequested('r-1'));
    await _settle();

    expect(bloc.state.status, ReceiptDetailStatus.failure);
    expect(bloc.state.errorMessage, 'Something went wrong.');

    repository.details = Right(testReceiptDetails());
    bloc.add(const ReceiptDetailRetried());
    await _settle();

    expect(repository.detailCalls, ['r-1', 'r-1']);
    expect(bloc.state.status, ReceiptDetailStatus.loaded);
  });

  test('the same receipt is not refetched; another one is', () async {
    bloc.add(const ReceiptDetailRequested('r-1'));
    await _settle();
    bloc.add(const ReceiptDetailRequested('r-1'));
    await _settle();
    bloc.add(const ReceiptDetailRequested('r-2'));
    await _settle();

    expect(repository.detailCalls, ['r-1', 'r-2']);
  });

  test('an answer for a receipt no longer shown is dropped', () async {
    repository.holdDetails = true;
    bloc.add(const ReceiptDetailRequested('r-1'));
    await _settle();
    bloc.add(const ReceiptDetailRequested('r-2'));
    await _settle();

    repository.details = Right(testReceiptDetails(id: 'r-2'));
    repository.heldDetails[1].complete();
    await _settle();
    repository.details = const Left(ServerFailure('Something went wrong.'));
    repository.heldDetails[0].complete();
    await _settle();

    expect(bloc.state.receiptId, 'r-2');
    expect(bloc.state.status, ReceiptDetailStatus.loaded);
    expect(bloc.state.receipt!.id, 'r-2');
  });
}
