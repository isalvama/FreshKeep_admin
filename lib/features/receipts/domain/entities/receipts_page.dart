import 'dart:math';

import 'package:equatable/equatable.dart';

import 'receipt_summary.dart';

/// One page of the receipts list, as the backend pages it (1-based).
class ReceiptsPage extends Equatable {
  final List<ReceiptSummary> receipts;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const ReceiptsPage({
    required this.receipts,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  /// 1-based position of the first row ("31" in "31–60 of 214"); 0 when the
  /// page is empty.
  int get firstIndex => receipts.isEmpty ? 0 : (page - 1) * size + 1;

  /// 1-based position of the last row ("60" in "31–60 of 214"); 0 when the
  /// page is empty.
  int get lastIndex => receipts.isEmpty
      ? 0
      : min(firstIndex + receipts.length - 1, totalElements);

  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  @override
  List<Object?> get props => [receipts, page, size, totalElements, totalPages];
}
