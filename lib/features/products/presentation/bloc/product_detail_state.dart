part of 'product_detail_bloc.dart';

enum ProductDetailStatus { loading, loaded, failure, notFound }

class ProductDetailState extends Equatable {
  /// Null until the page asks for a product.
  final String? productId;
  final ProductDetailStatus status;
  final ProductDetails? product;
  final String? errorMessage;

  const ProductDetailState({
    this.productId,
    this.status = ProductDetailStatus.loading,
    this.product,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [productId, status, product, errorMessage];
}
