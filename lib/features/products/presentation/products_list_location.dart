import 'products_list_query.dart';

/// The last products list URL visited this session, so "← Back to products"
/// on a product's page returns to the same sort, filters and page. In memory
/// only (a get_it singleton): a reload starts from the default again.
class ProductsListLocation {
  String _value = productsListLocation(kDefaultProductsListQuery);

  String get value => _value;

  /// Records a list URL. Anything that isn't the products list is ignored.
  void remember(String location) {
    if (Uri.parse(location).path == kProductsPath) _value = location;
  }
}
