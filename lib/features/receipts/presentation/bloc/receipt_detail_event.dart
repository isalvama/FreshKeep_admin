part of 'receipt_detail_bloc.dart';

sealed class ReceiptDetailEvent {
  const ReceiptDetailEvent();
}

/// The page opened, or its URL now names another receipt.
final class ReceiptDetailRequested extends ReceiptDetailEvent {
  final String receiptId;

  const ReceiptDetailRequested(this.receiptId);
}

/// The Retry button.
final class ReceiptDetailRetried extends ReceiptDetailEvent {
  const ReceiptDetailRetried();
}
