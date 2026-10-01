part of 'receipts_list_bloc.dart';

sealed class ReceiptsListEvent {
  const ReceiptsListEvent();
}

/// The URL's range, creator or page changed (or the page opened).
final class ReceiptsListRequested extends ReceiptsListEvent {
  final ReceiptsListQuery query;

  const ReceiptsListRequested(this.query);
}

/// The Retry (or refresh) button: reloads the current page, and the creator
/// label if it failed.
final class ReceiptsListRetried extends ReceiptsListEvent {
  const ReceiptsListRetried();
}
