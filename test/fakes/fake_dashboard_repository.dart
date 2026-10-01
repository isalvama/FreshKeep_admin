import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/date_range.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/repositories/dashboard_repository.dart';

typedef DailyResult = Either<AdminFailure, List<DailyCount>>;
typedef TypesResult = Either<AdminFailure, List<ProductTypeCount>>;

/// Answers each endpoint from a settable result, and records calls.
///
/// When [holdRequests] is true, daily calls wait until [release] is called
/// for their range, so tests can control the order responses arrive in.
class FakeDashboardRepository implements DashboardRepository {
  DailyResult registrations = const Right([]);
  DailyResult products = const Right([]);
  DailyResult receipts = const Right([]);
  TypesResult productTypes = const Right([]);

  bool holdRequests = false;
  final _held = <DateRange, Completer<void>>{};

  final List<(String, DateRange?)> calls = [];

  int callsTo(String endpoint) => calls.where((c) => c.$1 == endpoint).length;

  void release(DateRange range) => _held[range]?.complete();

  Future<DailyResult> _daily(
    String name,
    DateRange range,
    DailyResult Function() result,
  ) async {
    calls.add((name, range));
    if (holdRequests) {
      await _held.putIfAbsent(range, Completer<void>.new).future;
    }
    return result();
  }

  @override
  Future<DailyResult> getUserRegistrations(DateRange range) =>
      _daily('registrations', range, () => registrations);

  @override
  Future<DailyResult> getProductsAdded(DateRange range) =>
      _daily('products', range, () => products);

  @override
  Future<DailyResult> getReceipts(DateRange range) =>
      _daily('receipts', range, () => receipts);

  @override
  Future<TypesResult> getProductTypeCounts() async {
    calls.add(('productTypes', null));
    return productTypes;
  }
}
