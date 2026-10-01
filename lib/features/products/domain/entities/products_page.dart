import 'package:equatable/equatable.dart';

import 'product_summary.dart';

/// One page of the products list (1-based). The backend returns no total, so
/// a full page is the only hint that another one may follow.
class ProductsPage extends Equatable {
  final List<ProductSummary> products;
  final int page;

  /// The page size that was requested.
  final int size;

  const ProductsPage({
    required this.products,
    required this.page,
    required this.size,
  });

  /// 1-based position of the first row ("31" in "Products 31–60"); 0 when
  /// the page is empty.
  int get firstIndex => products.isEmpty ? 0 : (page - 1) * size + 1;

  /// 1-based position of the last row; 0 when the page is empty.
  int get lastIndex => products.isEmpty ? 0 : firstIndex + products.length - 1;

  bool get hasPrevious => page > 1;

  /// A full page may be followed by more; when the last page is exactly full,
  /// the next one comes back empty.
  bool get hasNext => products.length == size;

  @override
  List<Object?> get props => [products, page, size];
}
