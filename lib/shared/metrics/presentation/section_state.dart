import 'package:equatable/equatable.dart';

enum SectionStatus { loading, loaded, failure }

/// One independently loaded part of a page (a card, a table). Parts load and
/// fail on their own, so one failing request doesn't blank the page.
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
