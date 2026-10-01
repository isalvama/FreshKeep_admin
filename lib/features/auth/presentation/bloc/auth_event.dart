part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AppStarted extends AuthEvent {
  const AppStarted();
}

final class LoggedIn extends AuthEvent {
  final Admin admin;

  const LoggedIn(this.admin);
}

final class LoggedOut extends AuthEvent {
  const LoggedOut();
}

/// Added by [AuthBloc] itself when [SessionExpiredNotifier] fires.
final class SessionExpired extends AuthEvent {
  const SessionExpired();
}
