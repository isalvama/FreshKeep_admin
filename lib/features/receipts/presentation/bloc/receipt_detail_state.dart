part of 'receipt_detail_bloc.dart';

enum ReceiptDetailStatus { loading, loaded, failure, notFound }

class ReceiptDetailState extends Equatable {
  /// Null until the page asks for a receipt.
  final String? receiptId;
  final ReceiptDetailStatus status;
  final ReceiptDetails? receipt;
  final String? errorMessage;

  const ReceiptDetailState({
    this.receiptId,
    this.status = ReceiptDetailStatus.loading,
    this.receipt,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [receiptId, status, receipt, errorMessage];
}
