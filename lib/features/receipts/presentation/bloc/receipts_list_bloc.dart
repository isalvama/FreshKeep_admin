import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/creators/domain/get_creator_label_usecase.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../domain/entities/receipts_page.dart';
import '../../domain/usecases/get_receipts_list_usecase.dart';
import '../receipts_list_query.dart';

part 'receipts_list_event.dart';
part 'receipts_list_state.dart';

/// Loads one page of receipts, plus the creator filter chip's label. The two
/// load in parallel and fail on their own: a chip that can't be labelled
/// never blocks the list.
class ReceiptsListBloc extends Bloc<ReceiptsListEvent, ReceiptsListState> {
  final GetReceiptsListUseCase getReceiptsListUseCase;
  final GetCreatorLabelUseCase getCreatorLabelUseCase;

  /// Injectable so tests control what "today" (and so each preset) means.
  final DateTime Function() today;

  /// Labels found this session, by id: paging through a creator's receipts
  /// doesn't look the email up again.
  final _creatorLabels = <String, String>{};

  bool _hasLoaded = false;

  /// Identifies the latest page request; older answers are dropped.
  int _pageRequest = 0;

  ReceiptsListBloc({
    required this.getReceiptsListUseCase,
    required this.getCreatorLabelUseCase,
    DateTime Function()? today,
  }) : today = today ?? DateTime.now,
       super(
         ReceiptsListState(
           query: kDefaultReceiptsListQuery,
           resolvedRange: kDefaultReceiptsListQuery.range.resolve(
             (today ?? DateTime.now)(),
           ),
         ),
       ) {
    on<ReceiptsListRequested>(_onRequested);
    on<ReceiptsListRetried>(_onRetried);
  }

  Future<void> _onRequested(
    ReceiptsListRequested event,
    Emitter<ReceiptsListState> emit,
  ) async {
    // The page dispatches on every URL read; an unchanged query isn't a reload.
    if (_hasLoaded && event.query == state.query) return;
    _hasLoaded = true;
    await _load(emit, event.query, retryFailedLabel: false);
  }

  Future<void> _onRetried(
    ReceiptsListRetried event,
    Emitter<ReceiptsListState> emit,
  ) => _load(emit, state.query, retryFailedLabel: true);

  Future<void> _load(
    Emitter<ReceiptsListState> emit,
    ReceiptsListQuery query, {
    required bool retryFailedLabel,
  }) async {
    final previous = state;
    final creatorId = query.creatorId;
    final creator = _label(
      creatorId,
      previousId: previous.query.creatorId,
      previous: previous.creatorLabel,
      retryFailed: retryFailedLabel,
    );
    final resolved = query.range.resolve(today());
    final request = ++_pageRequest;
    emit(
      ReceiptsListState(
        query: query,
        resolvedRange: resolved,
        creatorLabel: creator.state,
      ),
    );

    await Future.wait([
      _loadPage(emit, query, resolved, request),
      if (creator.fetch) _loadCreatorLabel(emit, creatorId!),
    ]);
  }

  /// The chip state to show for [id], and whether it must be looked up. A
  /// lookup already running for the same id is left to finish; a failed one
  /// is only retried by Retry, not by paging.
  ({SectionState<String>? state, bool fetch}) _label(
    String? id, {
    required String? previousId,
    required SectionState<String>? previous,
    required bool retryFailed,
  }) {
    if (id == null) return (state: null, fetch: false);
    final cached = _creatorLabels[id];
    if (cached != null) {
      return (state: SectionState.loaded(cached), fetch: false);
    }
    if (id == previousId && previous != null) {
      final failed = previous.status == SectionStatus.failure;
      if (!failed || !retryFailed) return (state: previous, fetch: false);
    }
    return (state: const SectionState<String>.loading(), fetch: true);
  }

  Future<void> _loadPage(
    Emitter<ReceiptsListState> emit,
    ReceiptsListQuery query,
    DateRange resolved,
    int request,
  ) async {
    final result = await getReceiptsListUseCase(
      resolved,
      creatorId: query.creatorId,
      page: query.page,
    );
    // A response for a query that is no longer shown is dropped.
    if (emit.isDone || request != _pageRequest) return;
    emit(
      state.copyWith(
        receipts: result.match(
          (failure) => SectionState.failure(failure.message),
          SectionState.loaded,
        ),
      ),
    );
  }

  Future<void> _loadCreatorLabel(
    Emitter<ReceiptsListState> emit,
    String creatorId,
  ) async {
    final result = await getCreatorLabelUseCase(creatorId);
    result.match((_) {}, (email) => _creatorLabels[creatorId] = email);
    // Dropped when the chip is gone or shows another creator by now.
    if (emit.isDone || state.query.creatorId != creatorId) return;
    emit(
      state.copyWith(
        creatorLabel: result.match(
          (failure) => SectionState.failure(failure.message),
          SectionState.loaded,
        ),
      ),
    );
  }
}
