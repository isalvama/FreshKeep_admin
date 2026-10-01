part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The stored session hasn't been checked yet.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class Authenticated extends AuthState {
  final Admin admin;

  const Authenticated(this.admin);

  @override
  List<Object?> get props => [admin];
}

final class Unauthenticated extends AuthState {
  /// True when the backend rejected the session mid-use (401), so the login
  /// page can explain why the admin is back there.
  final bool sessionExpired;

  const Unauthenticated({this.sessionExpired = false});

  @override
  List<Object?> get props => [sessionExpired];
}
