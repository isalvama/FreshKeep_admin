import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_bloc.dart';

part 'login_state.dart';

class LoginSubmitted {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});
}

class LoginBloc extends Bloc<LoginSubmitted, LoginState> {
  final LoginUseCase loginUseCase;
  final AuthBloc authBloc;

  LoginBloc({required this.loginUseCase, required this.authBloc})
    : super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginSubmitting());
    final result = await loginUseCase(event.email, event.password);
    result.match((failure) => emit(LoginFailure(failure.message)), (admin) {
      authBloc.add(LoggedIn(admin));
      emit(LoginSuccess(admin));
    });
  }
}
