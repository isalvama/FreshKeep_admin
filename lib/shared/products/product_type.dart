import '../metrics/presentation/format.dart';

/// The backend's `ProductType` values, in backend order. There is no endpoint
/// listing them all (`/product-types` only returns types in use), so they are
/// pinned here and by a test.
const kProductTypes = [
  'FRUITS',
  'VEGETABLES',
  'OTHER_FRESH_PRODUCTS',
  'MEAT',
  'SEAFOOD',
  'DAIRY',
  'DELI',
  'BAKERY',
  'PANTRY',
  'SNACKS',
  'SWEETS',
  'FROZEN_FOODS',
  'ICE_CREAM_AND_DESSERTS',
  'BEVERAGES',
  'INTERNATIONAL',
  'SAUCES',
  'OTHER',
];

/// `OTHER_FRESH_PRODUCTS` → "Other fresh products". Derived from the raw
/// value, so types the app doesn't know yet still read well.
String productTypeLabel(String raw) => humanizeConstant(raw);
