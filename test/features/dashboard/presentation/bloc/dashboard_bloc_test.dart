import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/daily_count.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/entities/selected_range.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/entities/product_type_count.dart';
import 'package:fresh_keep_admin/features/dashboard/domain/usecases/get_product_type_counts_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_products_added_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_receipts_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_user_registrations_usecase.dart';
import 'package:fresh_keep_admin/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/section_state.dart';

import '../../../../fakes/fake_dashboard_repository.dart';

final _today = DateTime(2026, 10, 1, 9);
const _last7 = PresetRange(RangePreset.last7);
const _last30 = PresetRange(RangePreset.last30);

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeDashboardRepository repository;
  late DashboardBloc bloc;

  setUp(() {
    repository = FakeDashboardRepository();
    bloc = DashboardBloc(
      getUserRegistrationsUseCase: GetUserRegistrationsUseCase(repository),
      getProductsAddedUseCase: GetProductsAddedUseCase(repository),
      getReceiptsUseCase: GetReceiptsUseCase(repository),
      getProductTypeCountsUseCase: GetProductTypeCountsUseCase(repository),
      today: () => _today,
    );
  });

  tearDown(() => bloc.close());

  test('starts on the default range with every section loading', () {
    expect(bloc.state.range, _last30);
    expect(bloc.state.registrations.status, SectionStatus.loading);
    expect(bloc.state.productTypes.status, SectionStatus.loading);
    expect(repository.calls, isEmpty);
  });

  group('DashboardRangeChanged', () {
    test(
      'the first one loads all four sections for the resolved range',
      () async {
        repository.registrations = Right([
          DailyCount(date: DateTime.utc(2026, 9, 30), count: 2),
        ]);
        repository.productTypes = const Right([
          ProductTypeCount(productType: 'DAIRY', count: 3),
        ]);

        bloc.add(const DashboardRangeChanged(_last7));
        await _settle();

        final state = bloc.state;
        expect(state.range, _last7);
        expect(state.resolvedRange.from, DateTime.utc(2026, 9, 25));
        expect(state.resolvedRange.to, DateTime.utc(2026, 10, 1));
        for (final section in [
          state.registrations,
          state.products,
          state.receipts,
          state.productTypes,
        ]) {
          expect(section.status, SectionStatus.loaded);
        }
        // Zero-filled through the use case: 7 days, one with activity.
        expect(state.registrations.data, hasLength(7));
        expect(
          state.registrations.data!.map((c) => c.count).reduce((a, b) => a + b),
          2,
        );
        expect(state.productTypes.data!.single.productType, 'DAIRY');
        expect(repository.calls.map((c) => c.$1).toSet(), {
          'registrations',
          'products',
          'receipts',
          'productTypes',
        });
        expect(
          repository.calls.where((c) => c.$2 != null).map((c) => c.$2).toSet(),
          {state.resolvedRange},
        );
      },
    );

    test(
      'later ones reload the daily sections but not product types',
      () async {
        bloc.add(const DashboardRangeChanged(_last30));
        await _settle();

        bloc.add(const DashboardRangeChanged(_last7));
        await _settle();

        expect(repository.callsTo('registrations'), 2);
        expect(repository.callsTo('products'), 2);
        expect(repository.callsTo('receipts'), 2);
        expect(repository.callsTo('productTypes'), 1);
        expect(bloc.state.registrations.data, hasLength(7));
      },
    );

    test('an unchanged range is not reloaded', () async {
      bloc.add(const DashboardRangeChanged(_last30));
      await _settle();

      bloc.add(const DashboardRangeChanged(_last30));
      await _settle();

      expect(repository.callsTo('registrations'), 1);
    });

    test('marks the daily sections loading while fetching', () async {
      repository.holdRequests = true;

      bloc.add(const DashboardRangeChanged(_last7));
      await _settle();

      expect(bloc.state.range, _last7);
      expect(bloc.state.registrations.status, SectionStatus.loading);
      expect(bloc.state.productTypes.status, SectionStatus.loaded);

      repository.release(bloc.state.resolvedRange);
      await _settle();
      expect(bloc.state.registrations.status, SectionStatus.loaded);
    });

    test(
      'a response for a range that is no longer current is dropped',
      () async {
        repository.holdRequests = true;
        final week = _last7.resolve(_today);
        final month = _last30.resolve(_today);

        bloc.add(const DashboardRangeChanged(_last30));
        await _settle();
        bloc.add(const DashboardRangeChanged(_last7));
        await _settle();

        // The 7-day answer arrives first, then the stale 30-day one.
        repository.release(week);
        await _settle();
        repository.release(month);
        await _settle();

        expect(bloc.state.range, _last7);
        expect(bloc.state.resolvedRange, week);
        expect(bloc.state.registrations.data, hasLength(7));
        expect(bloc.state.products.data, hasLength(7));
        expect(bloc.state.receipts.data, hasLength(7));
      },
    );
  });

  test('one failing section leaves the others loaded', () async {
    repository.products = const Left(ServerFailure('Something went wrong.'));

    bloc.add(const DashboardRangeChanged(_last7));
    await _settle();

    expect(bloc.state.products.status, SectionStatus.failure);
    expect(bloc.state.products.errorMessage, 'Something went wrong.');
    expect(bloc.state.registrations.status, SectionStatus.loaded);
    expect(bloc.state.receipts.status, SectionStatus.loaded);
    expect(bloc.state.productTypes.status, SectionStatus.loaded);
  });

  test('DashboardRefreshed reloads all four sections', () async {
    bloc.add(const DashboardRangeChanged(_last7));
    await _settle();

    bloc.add(const DashboardRefreshed());
    await _settle();

    for (final endpoint in [
      'registrations',
      'products',
      'receipts',
      'productTypes',
    ]) {
      expect(repository.callsTo(endpoint), 2, reason: endpoint);
    }
    expect(bloc.state.range, _last7);
  });

  group('DashboardSectionRetried', () {
    test('reloads only that daily section, for the current range', () async {
      repository.receipts = const Left(
        NetworkFailure('Could not reach the server.'),
      );
      bloc.add(const DashboardRangeChanged(_last7));
      await _settle();
      expect(bloc.state.receipts.status, SectionStatus.failure);

      repository.receipts = const Right([]);
      bloc.add(const DashboardSectionRetried(DashboardSection.receipts));
      await _settle();

      expect(bloc.state.receipts.status, SectionStatus.loaded);
      expect(repository.callsTo('receipts'), 2);
      expect(repository.callsTo('registrations'), 1);
      expect(repository.callsTo('products'), 1);
      expect(repository.callsTo('productTypes'), 1);
      expect(repository.calls.last.$2, _last7.resolve(_today));
    });

    test('reloads only product types', () async {
      repository.productTypes = const Left(
        ServerFailure('Something went wrong.'),
      );
      bloc.add(const DashboardRangeChanged(_last7));
      await _settle();

      repository.productTypes = const Right([]);
      bloc.add(const DashboardSectionRetried(DashboardSection.productTypes));
      await _settle();

      expect(bloc.state.productTypes.status, SectionStatus.loaded);
      expect(repository.callsTo('productTypes'), 2);
      expect(repository.callsTo('registrations'), 1);
    });
  });
}
