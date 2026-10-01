import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/metrics/presentation/section_state.dart';
import '../../domain/entities/products_page.dart';
import '../../domain/entities/receipt_label.dart';
import '../../domain/usecases/get_creator_label_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/get_receipt_label_usecase.dart';
import '../products_list_query.dart';

part 'products_list_event.dart';
part 'products_list_state.dart';

/// Loads one page of products, plus the labels of the creator and receipt
/// filter chips. The three load in parallel and fail on their own: a chip
/// that can't be labelled never blocks the list.
class ProductsListBloc extends Bloc<ProductsListEvent, ProductsListState> {
  final GetProductsUseCase getProductsUseCase;
  final GetCreatorLabelUseCase getCreatorLabelUseCase;
  final GetReceiptLabelUseCase getReceiptLabelUseCase;

  /// What the expiration badges count from; injectable for tests.
  final DateTime Function() today;

  /// Labels found this session, by id: paging through a filtered list
  /// doesn't look them up again.
  final _creatorLabels = <String, String>{};
  final _receiptLabels = <String, ReceiptLabel>{};

  bool _hasLoaded = false;

  /// Identifies the latest page request; older answers are dropped.
  int _pageRequest = 0;

  ProductsListBloc({
    required this.getProductsUseCase,
    required this.getCreatorLabelUseCase,
    required this.getReceiptLabelUseCase,
    DateTime Function()? today,
  }) : today = today ?? DateTime.now,
       super(const ProductsListState(query: kDefaultProductsListQuery)) {
    on<ProductsListRequested>(_onRequested);
    on<ProductsListRetried>(_onRetried);
  }

  Future<void> _onRequested(
    ProductsListRequested event,
    Emitter<ProductsListState> emit,
  ) async {
    // The page dispatches on every URL read; an unchanged query isn't a reload.
    if (_hasLoaded && event.query == state.query) return;
    _hasLoaded = true;
    await _load(emit, event.query, retryFailedLabels: false);
  }

  Future<void> _onRetried(
    ProductsListRetried event,
    Emitter<ProductsListState> emit,
  ) => _load(emit, state.query, retryFailedLabels: true);

  Future<void> _load(
    Emitter<ProductsListState> emit,
    ProductsListQuery query, {
    required bool retryFailedLabels,
  }) async {
    final previous = state;
    final filters = query.filters;
    final creator = _label(
      filters.creatorId,
      cache: _creatorLabels,
      previousId: previous.query.filters.creatorId,
      previous: previous.creatorLabel,
      retryFailed: retryFailedLabels,
    );
    final receipt = _label(
      filters.receiptId,
      cache: _receiptLabels,
      previousId: previous.query.filters.receiptId,
      previous: previous.receiptLabel,
      retryFailed: retryFailedLabels,
    );
    final request = ++_pageRequest;
    emit(
      ProductsListState(
        query: query,
        creatorLabel: creator.state,
        receiptLabel: receipt.state,
      ),
    );

    await Future.wait([
      _loadPage(emit, query, request),
      if (creator.fetch) _loadCreatorLabel(emit, filters.creatorId!),
      if (receipt.fetch) _loadReceiptLabel(emit, filters.receiptId!),
    ]);
  }

  /// The chip state to show for [id], and whether it must be looked up.
  /// A lookup already running for the same id is left to finish; a failed
  /// one is only retried by Retry, not by paging.
  ({SectionState<T>? state, bool fetch}) _label<T>(
    String? id, {
    required Map<String, T> cache,
    required String? previousId,
    required SectionState<T>? previous,
    required bool retryFailed,
  }) {
    if (id == null) return (state: null, fetch: false);
    final cached = cache[id];
    if (cached != null) {
      return (state: SectionState.loaded(cached), fetch: false);
    }
    if (id == previousId && previous != null) {
      final failed = previous.status == SectionStatus.failure;
      if (!failed || !retryFailed) return (state: previous, fetch: false);
    }
    return (state: SectionState<T>.loading(), fetch: true);
  }

  Future<void> _loadPage(
    Emitter<ProductsListState> emit,
    ProductsListQuery query,
    int request,
  ) async {
    final result = await getProductsUseCase(query.filters, page: query.page);
    // A response for a query that is no longer shown is dropped.
    if (emit.isDone || request != _pageRequest) return;
    emit(
      state.copyWith(
        products: result.match(
          (failure) => SectionState.failure(failure.message),
          SectionState.loaded,
        ),
      ),
    );
  }

  Future<void> _loadCreatorLabel(
    Emitter<ProductsListState> emit,
    String creatorId,
  ) async {
    final result = await getCreatorLabelUseCase(creatorId);
    result.match((_) {}, (email) => _creatorLabels[creatorId] = email);
    // Dropped when the chip is gone or shows another creator by now.
    if (emit.isDone || state.query.filters.creatorId != creatorId) return;
    emit(
      state.copyWith(
        creatorLabel: result.match(
          (failure) => SectionState.failure(failure.message),
          SectionState.loaded,
        ),
      ),
    );
  }

  Future<void> _loadReceiptLabel(
    Emitter<ProductsListState> emit,
    String receiptId,
  ) async {
    final result = await getReceiptLabelUseCase(receiptId);
    result.match((_) {}, (label) => _receiptLabels[receiptId] = label);
    if (emit.isDone || state.query.filters.receiptId != receiptId) return;
    emit(
      state.copyWith(
        receiptLabel: result.match(
          (failure) => SectionState.failure(failure.message),
          SectionState.loaded,
        ),
      ),
    );
  }
}
