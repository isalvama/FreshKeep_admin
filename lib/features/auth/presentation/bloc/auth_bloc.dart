import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/session_expired_notifier.dart';
import '../../domain/entities/admin.dart';
import '../../domain/usecases/get_current_admin_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide session state. Drives the router's redirects.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentAdminUseCase getCurrentAdminUseCase;
  final LogoutUseCase logoutUseCase;
  late final StreamSubscription<void> _sessionExpiredSubscription;

  AuthBloc({
    required this.getCurrentAdminUseCase,
    required this.logoutUseCase,
    required SessionExpiredNotifier sessionExpiredNotifier,
  }) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<SessionExpired>(_onSessionExpired);
    _sessionExpiredSubscription = sessionExpiredNotifier.stream.listen(
      (_) => add(const SessionExpired()),
    );
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) {
    final admin = getCurrentAdminUseCase();
    emit(admin != null ? Authenticated(admin) : const Unauthenticated());
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(Authenticated(event.admin));
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) {
    logoutUseCase();
    emit(const Unauthenticated());
  }

  void _onSessionExpired(SessionExpired event, Emitter<AuthState> emit) {
    // Several requests can fail with 401 at once; only the first logs out.
    if (state is! Authenticated) return;
    logoutUseCase();
    emit(const Unauthenticated(sessionExpired: true));
  }

  @override
  Future<void> close() async {
    await _sessionExpiredSubscription.cancel();
    return super.close();
  }
}
