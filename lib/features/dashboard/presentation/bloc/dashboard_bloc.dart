import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/daily_count.dart';
import '../../domain/entities/dashboard_range.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/product_type_count.dart';
import '../../domain/usecases/get_product_type_counts_usecase.dart';
import '../../domain/usecases/get_products_added_usecase.dart';
import '../../domain/usecases/get_receipts_usecase.dart';
import '../../domain/usecases/get_user_registrations_usecase.dart';
import '../dashboard_query.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

const _dailySections = [
  DashboardSection.registrations,
  DashboardSection.products,
  DashboardSection.receipts,
];

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetUserRegistrationsUseCase getUserRegistrationsUseCase;
  final GetProductsAddedUseCase getProductsAddedUseCase;
  final GetReceiptsUseCase getReceiptsUseCase;
  final GetProductTypeCountsUseCase getProductTypeCountsUseCase;

  /// Injectable so tests control what "today" (and so each preset) means.
  final DateTime Function() today;

  bool _hasLoaded = false;

  DashboardBloc({
    required this.getUserRegistrationsUseCase,
    required this.getProductsAddedUseCase,
    required this.getReceiptsUseCase,
    required this.getProductTypeCountsUseCase,
    DateTime Function()? today,
  }) : today = today ?? DateTime.now,
       super(
         DashboardState(
           range: kDefaultDashboardRange,
           resolvedRange: kDefaultDashboardRange.resolve(
             (today ?? DateTime.now)(),
           ),
         ),
       ) {
    on<DashboardRangeChanged>(_onRangeChanged);
    on<DashboardRefreshed>(_onRefreshed);
    on<DashboardSectionRetried>(_onSectionRetried);
  }

  Future<void> _onRangeChanged(
    DashboardRangeChanged event,
    Emitter<DashboardState> emit,
  ) async {
    // The page dispatches on every URL read; an unchanged range isn't a reload.
    if (_hasLoaded && event.range == state.range) return;
    final isFirstLoad = !_hasLoaded;
    _hasLoaded = true;

    await _load(
      emit,
      range: event.range,
      sections: [
        ..._dailySections,
        if (isFirstLoad) DashboardSection.productTypes,
      ],
    );
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) => _load(emit, range: state.range, sections: DashboardSection.values);

  Future<void> _onSectionRetried(
    DashboardSectionRetried event,
    Emitter<DashboardState> emit,
  ) async {
    final resolved = state.resolvedRange;
    if (event.section == DashboardSection.productTypes) {
      emit(state.copyWith(productTypes: const SectionState.loading()));
      await _loadProductTypes(emit);
    } else {
      emit(state.withDaily(event.section, const SectionState.loading()));
      await _loadDaily(emit, event.section, resolved);
    }
  }

  /// Marks [sections] loading for [range] (re-resolved against today, so a
  /// preset follows the date), then fetches them in parallel.
  Future<void> _load(
    Emitter<DashboardState> emit, {
    required DashboardRange range,
    required List<DashboardSection> sections,
  }) async {
    final resolved = range.resolve(today());
    var next = state.copyWith(range: range, resolvedRange: resolved);
    for (final section in sections) {
      next = section == DashboardSection.productTypes
          ? next.copyWith(productTypes: const SectionState.loading())
          : next.withDaily(section, const SectionState.loading());
    }
    emit(next);

    await Future.wait([
      for (final section in sections)
        section == DashboardSection.productTypes
            ? _loadProductTypes(emit)
            : _loadDaily(emit, section, resolved),
    ]);
  }

  Future<void> _loadDaily(
    Emitter<DashboardState> emit,
    DashboardSection section,
    DateRange resolved,
  ) async {
    final result = await switch (section) {
      DashboardSection.registrations => getUserRegistrationsUseCase(resolved),
      DashboardSection.products => getProductsAddedUseCase(resolved),
      DashboardSection.receipts => getReceiptsUseCase(resolved),
      DashboardSection.productTypes => throw ArgumentError.value(section),
    };
    // A response for a range that is no longer shown is dropped.
    if (emit.isDone || state.resolvedRange != resolved) return;
    emit(state.withDaily(section, _toSection(result)));
  }

  Future<void> _loadProductTypes(Emitter<DashboardState> emit) async {
    final result = await getProductTypeCountsUseCase();
    if (emit.isDone) return;
    emit(state.copyWith(productTypes: _toSection(result)));
  }

  static SectionState<T> _toSection<T>(Either<AdminFailure, T> result) =>
      result.match(
        (failure) => SectionState.failure(failure.message),
        SectionState.loaded,
      );
}
