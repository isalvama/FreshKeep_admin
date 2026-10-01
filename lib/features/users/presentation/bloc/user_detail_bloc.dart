import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/metrics/domain/entities/daily_count.dart';
import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../../../shared/metrics/domain/entities/selected_range.dart';
import '../../../../shared/metrics/domain/usecases/get_products_added_usecase.dart';
import '../../../../shared/metrics/domain/usecases/get_receipts_usecase.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../domain/entities/user_details.dart';
import '../../domain/usecases/get_user_details_usecase.dart';

part 'user_detail_event.dart';
part 'user_detail_state.dart';

/// The activity charts on a user's page always cover the last 30 days.
const kUserActivityRange = PresetRange(RangePreset.last30);

class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  final GetUserDetailsUseCase getUserDetailsUseCase;
  final GetProductsAddedUseCase getProductsAddedUseCase;
  final GetReceiptsUseCase getReceiptsUseCase;

  /// Injectable so tests control what "the last 30 days" means.
  final DateTime Function() today;

  UserDetailBloc({
    required this.getUserDetailsUseCase,
    required this.getProductsAddedUseCase,
    required this.getReceiptsUseCase,
    DateTime Function()? today,
  }) : today = today ?? DateTime.now,
       super(
         UserDetailState(
           userId: '',
           activityRange: kUserActivityRange.resolve((today ?? DateTime.now)()),
         ),
       ) {
    on<UserDetailRequested>(_onRequested);
    on<UserDetailSectionRetried>(_onSectionRetried);
  }

  Future<void> _onRequested(
    UserDetailRequested event,
    Emitter<UserDetailState> emit,
  ) async {
    // The page dispatches on every rebuild; the same user isn't a reload.
    if (event.userId == state.userId) return;

    emit(
      UserDetailState(
        userId: event.userId,
        activityRange: kUserActivityRange.resolve(today()),
      ),
    );
    await Future.wait([
      for (final section in UserDetailSection.values)
        _load(emit, section, event.userId),
    ]);
  }

  Future<void> _onSectionRetried(
    UserDetailSectionRetried event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(switch (event.section) {
      // A new details attempt clears a previous "not found".
      UserDetailSection.details => state.copyWith(
        details: const SectionState.loading(),
        userNotFound: false,
      ),
      UserDetailSection.productsActivity => state.copyWith(
        productsActivity: const SectionState.loading(),
      ),
      UserDetailSection.receiptsActivity => state.copyWith(
        receiptsActivity: const SectionState.loading(),
      ),
    });
    await _load(emit, event.section, state.userId);
  }

  Future<void> _load(
    Emitter<UserDetailState> emit,
    UserDetailSection section,
    String userId,
  ) async {
    final range = state.activityRange;
    switch (section) {
      case UserDetailSection.details:
        final result = await getUserDetailsUseCase(userId);
        if (_isStale(emit, userId)) return;
        emit(
          state.copyWith(
            details: _toSection(result),
            // The backend answers 400 for a missing user and for a malformed
            // id alike.
            userNotFound: result.getLeft().toNullable() is ValidationFailure,
          ),
        );
      case UserDetailSection.productsActivity:
        final result = await getProductsAddedUseCase(range, creatorId: userId);
        if (_isStale(emit, userId)) return;
        emit(state.copyWith(productsActivity: _toSection(result)));
      case UserDetailSection.receiptsActivity:
        final result = await getReceiptsUseCase(range, creatorId: userId);
        if (_isStale(emit, userId)) return;
        emit(state.copyWith(receiptsActivity: _toSection(result)));
    }
  }

  /// A response for a user no longer shown is dropped.
  bool _isStale(Emitter<UserDetailState> emit, String userId) =>
      emit.isDone || state.userId != userId;

  static SectionState<T> _toSection<T>(Either<AdminFailure, T> result) =>
      result.match(
        (failure) => SectionState.failure(failure.message),
        SectionState.loaded,
      );
}
