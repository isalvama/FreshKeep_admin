import '../../domain/entities/money.dart';

/// A price needs both its amount and its currency; with either missing there
/// is nothing sensible to show, so the product has no price.
Money? readMoney(Object? amount, Object? currency) {
  if (amount == null || currency == null) return null;
  return Money(amount: amount as num, currency: currency as String);
}
