import 'package:equatable/equatable.dart';

/// A price: an amount in a currency (an ISO code such as `USD`).
class Money extends Equatable {
  final num amount;
  final String currency;

  const Money({required this.amount, required this.currency});

  @override
  List<Object?> get props => [amount, currency];
}
