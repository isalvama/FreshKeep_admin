import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_summary.dart';
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipts_page.dart';

ReceiptsPage _page({
  required int page,
  required int rows,
  int total = 214,
  int pages = 8,
}) => ReceiptsPage(
  receipts: [
    for (var i = 0; i < rows; i++)
      ReceiptSummary(
        id: 'r$i',
        creatorId: null,
        creatorEmail: null,
        creatorUsername: null,
        spaceName: null,
        storeName: null,
        purchaseDate: DateTime.utc(2026, 9, 8),
        productCount: 0,
      ),
  ],
  page: page,
  size: 30,
  totalElements: total,
  totalPages: pages,
);

void main() {
  test('page 2 of 214 is 31–60, with both neighbours', () {
    final page = _page(page: 2, rows: 30);
    expect((page.firstIndex, page.lastIndex), (31, 60));
    expect((page.hasPrevious, page.hasNext), (true, true));
  });

  test('the last, partial page is 211–214 with no next', () {
    final page = _page(page: 8, rows: 4);
    expect((page.firstIndex, page.lastIndex), (211, 214));
    expect(page.hasNext, isFalse);
  });

  test('page 1 has no previous', () {
    expect(_page(page: 1, rows: 30).hasPrevious, isFalse);
  });

  test('a page past the end is 0–0 with no next', () {
    final page = _page(page: 9, rows: 0, total: 0, pages: 0);
    expect((page.firstIndex, page.lastIndex), (0, 0));
    expect(page.hasNext, isFalse);
  });
}
