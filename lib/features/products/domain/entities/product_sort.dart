/// The orders the backend's `/admin/products` supports.
enum ProductSort {
  nameAsc('NAME_ASC'),
  nameDesc('NAME_DESC'),
  expirationAsc('EXPIRATION_DATE_ASC'),
  expirationDesc('EXPIRATION_DATE_DESC'),
  priceAsc('PRICE_ASC'),
  priceDesc('PRICE_DESC');

  /// The backend's `sort` value, e.g. `EXPIRATION_DATE_ASC`.
  final String backendValue;

  const ProductSort(this.backendValue);

  /// The URL's `sort` value, e.g. `expiration_date_asc`.
  String get urlValue => backendValue.toLowerCase();

  /// The sort for a URL value, or null when it isn't one.
  static ProductSort? fromUrlValue(String? value) {
    for (final sort in values) {
      if (sort.urlValue == value) return sort;
    }
    return null;
  }
}
