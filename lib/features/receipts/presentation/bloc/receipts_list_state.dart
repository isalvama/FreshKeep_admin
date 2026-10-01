part of 'receipts_list_bloc.dart';

class ReceiptsListState extends Equatable {
  final ReceiptsListQuery query;

  /// [query]'s range resolved against "today" when it was last loaded.
  final DateRange resolvedRange;
  final SectionState<ReceiptsPage> receipts;

  /// The creator filter chip's email; null when there is no creator filter.
  final SectionState<String>? creatorLabel;

  const ReceiptsListState({
    required this.query,
    required this.resolvedRange,
    this.receipts = const SectionState.loading(),
    this.creatorLabel,
  });

  /// The chip can only be updated here, never removed: it follows [query].
  ReceiptsListState copyWith({
    SectionState<ReceiptsPage>? receipts,
    SectionState<String>? creatorLabel,
  }) => ReceiptsListState(
    query: query,
    resolvedRange: resolvedRange,
    receipts: receipts ?? this.receipts,
    creatorLabel: creatorLabel ?? this.creatorLabel,
  );

  @override
  List<Object?> get props => [query, resolvedRange, receipts, creatorLabel];
}
