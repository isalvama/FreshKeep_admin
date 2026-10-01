import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/usecases/get_product_details_usecase.dart';

part 'product_detail_event.dart';
part 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetailsUseCase getProductDetailsUseCase;

  /// What the expiration badge counts from; injectable for tests.
  final DateTime Function() today;

  /// Identifies the latest request; older answers are dropped.
  int _request = 0;

  ProductDetailBloc({
    required this.getProductDetailsUseCase,
    DateTime Function()? today,
  }) : today = today ?? DateTime.now,
       super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested);
    on<ProductDetailRetried>(_onRetried);
  }

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    // The page dispatches on every rebuild; the same product isn't a reload.
    if (event.productId == state.productId) return;
    await _load(emit, event.productId);
  }

  Future<void> _onRetried(
    ProductDetailRetried event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = state.productId;
    if (productId != null) await _load(emit, productId);
  }

  Future<void> _load(Emitter<ProductDetailState> emit, String productId) async {
    final request = ++_request;
    emit(ProductDetailState(productId: productId));

    final result = await getProductDetailsUseCase(productId);
    if (emit.isDone || request != _request) return;
    emit(
      result.match(
        (failure) => ProductDetailState(
          productId: productId,
          // The backend answers 400 for an unknown or malformed id.
          status: failure is ValidationFailure
              ? ProductDetailStatus.notFound
              : ProductDetailStatus.failure,
          errorMessage: failure.message,
        ),
        (product) => ProductDetailState(
          productId: productId,
          status: ProductDetailStatus.loaded,
          product: product,
        ),
      ),
    );
  }
}
