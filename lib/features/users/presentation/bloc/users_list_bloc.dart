import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/metrics/domain/entities/date_range.dart';
import '../../../../shared/metrics/presentation/section_state.dart';
import '../../domain/entities/users_page.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../users_list_query.dart';

part 'users_list_event.dart';
part 'users_list_state.dart';

class UsersListBloc extends Bloc<UsersListEvent, UsersListState> {
  final GetUsersUseCase getUsersUseCase;

  /// Injectable so tests control what "today" (and so each preset) means.
  final DateTime Function() today;

  bool _hasLoaded = false;

  UsersListBloc({required this.getUsersUseCase, DateTime Function()? today})
    : today = today ?? DateTime.now,
      super(
        UsersListState(
          query: kDefaultUsersListQuery,
          resolvedRange: kDefaultUsersListQuery.range.resolve(
            (today ?? DateTime.now)(),
          ),
        ),
      ) {
    on<UsersListQueryChanged>(_onQueryChanged);
    on<UsersListRetried>(_onRetried);
  }

  Future<void> _onQueryChanged(
    UsersListQueryChanged event,
    Emitter<UsersListState> emit,
  ) async {
    // The page dispatches on every URL read; an unchanged query isn't a reload.
    if (_hasLoaded && event.query == state.query) return;
    _hasLoaded = true;
    await _load(emit, event.query);
  }

  Future<void> _onRetried(
    UsersListRetried event,
    Emitter<UsersListState> emit,
  ) => _load(emit, state.query);

  Future<void> _load(Emitter<UsersListState> emit, UsersListQuery query) async {
    final resolved = query.range.resolve(today());
    emit(
      UsersListState(
        query: query,
        resolvedRange: resolved,
        users: const SectionState.loading(),
      ),
    );

    final result = await getUsersUseCase(resolved, page: query.page);
    // A response for a query that is no longer shown is dropped.
    if (emit.isDone ||
        state.query != query ||
        state.resolvedRange != resolved) {
      return;
    }
    emit(
      state.copyWith(
        users: result.match(
          (failure) => SectionState.failure(failure.message),
          SectionState.loaded,
        ),
      ),
    );
  }
}
