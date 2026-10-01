import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_product_details_usecase.dart';
import 'package:fresh_keep_admin/features/products/presentation/bloc/product_detail_bloc.dart';

import '../../../../fakes/fake_products_repository.dart';

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeProductsRepository repository;
  late ProductDetailBloc bloc;

  setUp(() {
    repository = FakeProductsRepository();
    bloc = ProductDetailBloc(
      getProductDetailsUseCase: GetProductDetailsUseCase(repository),
    );
  });

  tearDown(() => bloc.close());

  test('starts loading, without fetching', () {
    expect(bloc.state, const ProductDetailState());
    expect(repository.detailCalls, isEmpty);
  });

  test('loads the requested product', () async {
    repository.holdDetails = true;

    bloc.add(const ProductDetailRequested('product-1'));
    await _settle();
    expect(bloc.state.productId, 'product-1');
    expect(bloc.state.status, ProductDetailStatus.loading);

    repository.heldDetails.single.complete();
    await _settle();
    expect(bloc.state.status, ProductDetailStatus.loaded);
    expect(bloc.state.product, testProductDetails());
  });

  test('a 400 (unknown or malformed id) is not found', () async {
    repository.details = const Left(
      ValidationFailure('Product with id x does not exist.'),
    );

    bloc.add(const ProductDetailRequested('x'));
    await _settle();

    expect(bloc.state.status, ProductDetailStatus.notFound);
  });

  test('other failures keep their message, and Retry reloads', () async {
    repository.details = const Left(ServerFailure('Something went wrong.'));
    bloc.add(const ProductDetailRequested('product-1'));
    await _settle();

    expect(bloc.state.status, ProductDetailStatus.failure);
    expect(bloc.state.errorMessage, 'Something went wrong.');

    repository.details = Right(testProductDetails());
    bloc.add(const ProductDetailRetried());
    await _settle();

    expect(repository.detailCalls, ['product-1', 'product-1']);
    expect(bloc.state.status, ProductDetailStatus.loaded);
  });

  test('the same product is not refetched; another one is', () async {
    bloc.add(const ProductDetailRequested('product-1'));
    await _settle();
    bloc.add(const ProductDetailRequested('product-1'));
    await _settle();
    bloc.add(const ProductDetailRequested('product-2'));
    await _settle();

    expect(repository.detailCalls, ['product-1', 'product-2']);
  });

  test('an answer for a product no longer shown is dropped', () async {
    repository.holdDetails = true;
    bloc.add(const ProductDetailRequested('product-1'));
    await _settle();
    bloc.add(const ProductDetailRequested('product-2'));
    await _settle();

    // product-2 arrives first, then the stale product-1 failure.
    repository.details = Right(testProductDetails(id: 'product-2'));
    repository.heldDetails[1].complete();
    await _settle();
    repository.details = const Left(ServerFailure('Something went wrong.'));
    repository.heldDetails[0].complete();
    await _settle();

    expect(bloc.state.productId, 'product-2');
    expect(bloc.state.status, ProductDetailStatus.loaded);
    expect(bloc.state.product!.id, 'product-2');
  });
}
