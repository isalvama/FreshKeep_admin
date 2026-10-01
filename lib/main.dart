import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/storage/web_session_storage.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  usePathUrlStrategy();
  setupServiceLocator(sessionStorage: const WebSessionStorage());
  runApp(App(authBloc: getIt<AuthBloc>()..add(const AppStarted())));
}
