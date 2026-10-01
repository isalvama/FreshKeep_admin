part of 'product_detail_bloc.dart';

sealed class ProductDetailEvent {
  const ProductDetailEvent();
}

/// The page opened, or its URL now names another product.
final class ProductDetailRequested extends ProductDetailEvent {
  final String productId;

  const ProductDetailRequested(this.productId);
}

/// The Retry button.
final class ProductDetailRetried extends ProductDetailEvent {
  const ProductDetailRetried();
}
