import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/app.dart';
import 'package:fresh_keep_admin/core/di/service_locator.dart';
import 'package:fresh_keep_admin/core/network/auth_interceptor.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';

import 'fakes/in_memory_session_storage.dart';

void main() {
  setUp(() => setupServiceLocator(sessionStorage: InMemorySessionStorage()));
  tearDown(() => getIt.reset());

  test('the service locator resolves the whole auth graph', () {
    expect(getIt<AuthBloc>(), same(getIt<AuthBloc>()));
    expect(getIt<LoginBloc>(), isNot(same(getIt<LoginBloc>())));
    expect(
      getIt<Dio>().interceptors.whereType<AuthInterceptor>(),
      hasLength(1),
    );
    expect(getIt<Dio>().options.baseUrl, 'http://localhost:8082');
  });

  testWidgets('the app boots to the login page', (tester) async {
    await tester.pumpWidget(
      App(authBloc: getIt<AuthBloc>()..add(const AppStarted())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
  });
}
