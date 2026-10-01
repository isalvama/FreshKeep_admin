part of 'dashboard_bloc.dart';

enum DashboardSection { registrations, products, receipts, productTypes }

enum SectionStatus { loading, loaded, failure }

/// One card's data. Cards load and fail independently.
class SectionState<T> extends Equatable {
  final SectionStatus status;
  final T? data;
  final String? errorMessage;

  const SectionState.loading()
    : status = SectionStatus.loading,
      data = null,
      errorMessage = null;

  const SectionState.loaded(T this.data)
    : status = SectionStatus.loaded,
      errorMessage = null;

  const SectionState.failure(String this.errorMessage)
    : status = SectionStatus.failure,
      data = null;

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class DashboardState extends Equatable {
  final DashboardRange range;

  /// [range] resolved against "today" when it was last loaded; the dates the
  /// daily sections show.
  final DateRange resolvedRange;
  final SectionState<List<DailyCount>> registrations;
  final SectionState<List<DailyCount>> products;
  final SectionState<List<DailyCount>> receipts;
  final SectionState<List<ProductTypeCount>> productTypes;

  const DashboardState({
    required this.range,
    required this.resolvedRange,
    this.registrations = const SectionState.loading(),
    this.products = const SectionState.loading(),
    this.receipts = const SectionState.loading(),
    this.productTypes = const SectionState.loading(),
  });

  SectionState<List<DailyCount>> daily(DashboardSection section) =>
      switch (section) {
        DashboardSection.registrations => registrations,
        DashboardSection.products => products,
        DashboardSection.receipts => receipts,
        DashboardSection.productTypes => throw ArgumentError.value(
          section,
          'section',
          'not a daily section',
        ),
      };

  DashboardState copyWith({
    DashboardRange? range,
    DateRange? resolvedRange,
    SectionState<List<DailyCount>>? registrations,
    SectionState<List<DailyCount>>? products,
    SectionState<List<DailyCount>>? receipts,
    SectionState<List<ProductTypeCount>>? productTypes,
  }) {
    return DashboardState(
      range: range ?? this.range,
      resolvedRange: resolvedRange ?? this.resolvedRange,
      registrations: registrations ?? this.registrations,
      products: products ?? this.products,
      receipts: receipts ?? this.receipts,
      productTypes: productTypes ?? this.productTypes,
    );
  }

  DashboardState withDaily(
    DashboardSection section,
    SectionState<List<DailyCount>> value,
  ) => switch (section) {
    DashboardSection.registrations => copyWith(registrations: value),
    DashboardSection.products => copyWith(products: value),
    DashboardSection.receipts => copyWith(receipts: value),
    DashboardSection.productTypes => throw ArgumentError.value(
      section,
      'section',
      'not a daily section',
    ),
  };

  @override
  List<Object?> get props => [
    range,
    resolvedRange,
    registrations,
    products,
    receipts,
    productTypes,
  ];
}
