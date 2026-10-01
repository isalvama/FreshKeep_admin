import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_filters.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_sort.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_creator_label_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_products_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_receipt_label_usecase.dart';
import 'package:fresh_keep_admin/features/products/presentation/bloc/products_list_bloc.dart';
import 'package:fresh_keep_admin/features/products/presentation/products_list_query.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/section_state.dart';

import '../../../../fakes/fake_products_repository.dart';

const _dairy = ProductsListQuery(filters: ProductFilters(productType: 'DAIRY'));
const _byCreator = ProductsListQuery(
  filters: ProductFilters(creatorId: kTestCreatorId),
);
const _byReceipt = ProductsListQuery(
  filters: ProductFilters(receiptId: kTestReceiptId),
);
const _byBoth = ProductsListQuery(
  filters: ProductFilters(creatorId: kTestCreatorId, receiptId: kTestReceiptId),
);

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeProductsRepository repository;
  late ProductsListBloc bloc;

  setUp(() {
    repository = FakeProductsRepository();
    bloc = ProductsListBloc(
      getProductsUseCase: GetProductsUseCase(repository),
      getCreatorLabelUseCase: GetCreatorLabelUseCase(repository),
      getReceiptLabelUseCase: GetReceiptLabelUseCase(repository),
    );
  });

  tearDown(() => bloc.close());

  test('starts on the default query, loading, without fetching', () {
    expect(bloc.state.query, kDefaultProductsListQuery);
    expect(bloc.state.products.status, SectionStatus.loading);
    expect(bloc.state.creatorLabel, isNull);
    expect(bloc.state.receiptLabel, isNull);
    expect(repository.listCalls, isEmpty);
  });

  test('loads the requested filters and page', () async {
    const query = ProductsListQuery(
      filters: ProductFilters(sort: ProductSort.priceAsc, productType: 'DAIRY'),
      page: 2,
    );

    bloc.add(const ProductsListRequested(query));
    await _settle();

    expect(repository.listCalls.single, (query.filters, 2));
    expect(bloc.state.query, query);
    expect(bloc.state.products.status, SectionStatus.loaded);
    expect(bloc.state.products.data!.firstIndex, 31);
  });

  test('without creator or receipt filters, no chip is looked up', () async {
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();

    expect(repository.creatorCalls, isEmpty);
    expect(repository.receiptCalls, isEmpty);
    expect(bloc.state.creatorLabel, isNull);
    expect(bloc.state.receiptLabel, isNull);
  });

  test('the page and both chip labels load in parallel', () async {
    repository
      ..holdProducts = true
      ..holdLabels = true;

    bloc.add(const ProductsListRequested(_byBoth));
    await _settle();

    // All three requests are out before any answer arrives.
    expect(repository.listCalls, hasLength(1));
    expect(repository.creatorCalls, [kTestCreatorId]);
    expect(repository.receiptCalls, [kTestReceiptId]);
    expect(bloc.state.products.status, SectionStatus.loading);
    expect(bloc.state.creatorLabel!.status, SectionStatus.loading);
    expect(bloc.state.receiptLabel!.status, SectionStatus.loading);

    for (final completer in [
      ...repository.heldLabels,
      ...repository.heldProducts,
    ]) {
      completer.complete();
    }
    await _settle();

    expect(bloc.state.products.status, SectionStatus.loaded);
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
    expect(bloc.state.receiptLabel, SectionState.loaded(testReceiptLabel));
  });

  test('a chip that fails does not block the page', () async {
    repository.creatorEmail = const Left(
      ServerFailure('Something went wrong.'),
    );

    bloc.add(const ProductsListRequested(_byCreator));
    await _settle();

    expect(bloc.state.products.status, SectionStatus.loaded);
    expect(bloc.state.creatorLabel!.status, SectionStatus.failure);
  });

  test('a page failure keeps its message, chips still load', () async {
    repository.productsPage = (_, _) => const Left(
      NetworkFailure('Could not reach the server. Please try again.'),
    );

    bloc.add(const ProductsListRequested(_byReceipt));
    await _settle();

    expect(bloc.state.products.status, SectionStatus.failure);
    expect(
      bloc.state.products.errorMessage,
      'Could not reach the server. Please try again.',
    );
    expect(bloc.state.receiptLabel!.status, SectionStatus.loaded);
  });

  test(
    'paging through a filtered list does not look the chips up again',
    () async {
      bloc.add(const ProductsListRequested(_byBoth));
      await _settle();
      bloc.add(ProductsListRequested(_byBoth.withPage(2)));
      await _settle();
      bloc.add(
        ProductsListRequested(
          _byBoth.withFilters(
            const ProductFilters(
              sort: ProductSort.nameDesc,
              creatorId: kTestCreatorId,
              receiptId: kTestReceiptId,
            ),
          ),
        ),
      );
      await _settle();

      expect(repository.listCalls, hasLength(3));
      expect(repository.creatorCalls, hasLength(1));
      expect(repository.receiptCalls, hasLength(1));
      expect(bloc.state.creatorLabel!.status, SectionStatus.loaded);
    },
  );

  test('a chip lookup still running is not started again by paging', () async {
    repository.holdLabels = true;

    bloc.add(const ProductsListRequested(_byCreator));
    await _settle();
    bloc.add(ProductsListRequested(_byCreator.withPage(2)));
    await _settle();

    expect(repository.creatorCalls, hasLength(1));
    expect(bloc.state.creatorLabel!.status, SectionStatus.loading);

    repository.heldLabels.single.complete();
    await _settle();
    expect(bloc.state.query.page, 2);
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('a failed chip is retried by Retry, not by paging', () async {
    repository.creatorEmail = const Left(
      ServerFailure('Something went wrong.'),
    );
    bloc.add(const ProductsListRequested(_byCreator));
    await _settle();
    bloc.add(ProductsListRequested(_byCreator.withPage(2)));
    await _settle();
    expect(repository.creatorCalls, hasLength(1));
    expect(bloc.state.creatorLabel!.status, SectionStatus.failure);

    repository.creatorEmail = const Right('alice@example.com');
    bloc.add(const ProductsListRetried());
    await _settle();

    expect(repository.creatorCalls, hasLength(2));
    expect(repository.listCalls.last.$2, 2);
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('Retry reloads the same page', () async {
    repository.productsPage = (_, _) =>
        const Left(ServerFailure('Something went wrong.'));
    bloc.add(ProductsListRequested(_dairy.withPage(3)));
    await _settle();

    repository.productsPage = (_, page) => Right(testProductsPage(page: page));
    bloc.add(const ProductsListRetried());
    await _settle();

    expect(repository.listCalls, hasLength(2));
    expect(repository.listCalls.last, (_dairy.filters, 3));
    expect(bloc.state.products.status, SectionStatus.loaded);
  });

  test('an unchanged query is not refetched', () async {
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();

    expect(repository.listCalls, hasLength(1));
  });

  test('a filter that comes back (✕ then Back) reuses its label', () async {
    bloc.add(const ProductsListRequested(_byCreator));
    await _settle();
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();
    bloc.add(const ProductsListRequested(_byCreator));
    await _settle();

    expect(repository.creatorCalls, hasLength(1));
    expect(
      bloc.state.creatorLabel,
      const SectionState.loaded('alice@example.com'),
    );
  });

  test('removing a filter drops its chip', () async {
    bloc.add(const ProductsListRequested(_byBoth));
    await _settle();
    bloc.add(const ProductsListRequested(_byReceipt));
    await _settle();

    expect(bloc.state.creatorLabel, isNull);
    expect(bloc.state.receiptLabel!.status, SectionStatus.loaded);
  });

  test('a page answer for a query no longer shown is dropped', () async {
    repository.holdProducts = true;

    bloc.add(ProductsListRequested(_dairy.withPage(2)));
    await _settle();
    bloc.add(const ProductsListRequested(_byReceipt));
    await _settle();

    // The current answer arrives first, then the stale page-2 one.
    repository.heldProducts[1].complete();
    await _settle();
    repository.heldProducts[0].complete();
    await _settle();

    expect(bloc.state.query, _byReceipt);
    expect(bloc.state.products.data!.page, 1);
  });

  test('a stale page answer for the same query (Retry while loading) is '
      'dropped', () async {
    repository.holdProducts = true;
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();
    bloc.add(const ProductsListRetried());
    await _settle();

    // The retry succeeds first; the original request then fails late.
    repository.heldProducts[1].complete();
    await _settle();
    repository.productsPage = (_, _) =>
        const Left(ServerFailure('Something went wrong.'));
    repository.heldProducts[0].complete();
    await _settle();

    expect(bloc.state.products.status, SectionStatus.loaded);
  });

  test('a chip answer for a creator no longer filtered is dropped', () async {
    repository.holdLabels = true;

    bloc.add(const ProductsListRequested(_byCreator));
    await _settle();
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();

    repository.heldLabels.single.complete();
    await _settle();

    expect(bloc.state.query, _dairy);
    expect(bloc.state.creatorLabel, isNull);
  });

  test('a chip answer for a receipt no longer filtered is dropped', () async {
    repository.holdLabels = true;

    bloc.add(const ProductsListRequested(_byReceipt));
    await _settle();
    bloc.add(const ProductsListRequested(_dairy));
    await _settle();

    repository.heldLabels.single.complete();
    await _settle();

    expect(bloc.state.query, _dairy);
    expect(bloc.state.receiptLabel, isNull);
  });
}
