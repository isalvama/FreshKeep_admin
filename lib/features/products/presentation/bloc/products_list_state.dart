part of 'products_list_bloc.dart';

class ProductsListState extends Equatable {
  final ProductsListQuery query;
  final SectionState<ProductsPage> products;

  /// The creator filter chip's email; null when there is no creator filter.
  final SectionState<String>? creatorLabel;

  /// The receipt filter chip's label; null when there is no receipt filter.
  final SectionState<ReceiptLabel>? receiptLabel;

  const ProductsListState({
    required this.query,
    this.products = const SectionState.loading(),
    this.creatorLabel,
    this.receiptLabel,
  });

  /// Chips can only be updated here, never removed: they follow [query].
  ProductsListState copyWith({
    SectionState<ProductsPage>? products,
    SectionState<String>? creatorLabel,
    SectionState<ReceiptLabel>? receiptLabel,
  }) => ProductsListState(
    query: query,
    products: products ?? this.products,
    creatorLabel: creatorLabel ?? this.creatorLabel,
    receiptLabel: receiptLabel ?? this.receiptLabel,
  );

  @override
  List<Object?> get props => [query, products, creatorLabel, receiptLabel];
}
