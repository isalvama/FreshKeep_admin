import '../domain/entities/money.dart';

/// `2.50 USD`: always two decimals, with the currency code.
String formatMoney(Money money) =>
    '${money.amount.toStringAsFixed(2)} ${money.currency}';
