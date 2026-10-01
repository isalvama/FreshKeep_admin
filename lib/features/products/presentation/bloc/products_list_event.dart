part of 'products_list_bloc.dart';

sealed class ProductsListEvent {
  const ProductsListEvent();
}

/// The URL's sort, filters or page changed (or the page opened).
final class ProductsListRequested extends ProductsListEvent {
  final ProductsListQuery query;

  const ProductsListRequested(this.query);
}

/// The Retry button: reloads the current page, and any chip label that
/// failed.
final class ProductsListRetried extends ProductsListEvent {
  const ProductsListRetried();
}
