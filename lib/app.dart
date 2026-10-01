import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'routes/app_router.dart';

class App extends StatefulWidget {
  final AuthBloc authBloc;

  const App({super.key, required this.authBloc});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Built once: rebuilding the router would reset navigation.
  late final GoRouter _router = buildAppRouter(widget.authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: widget.authBloc),
        BlocProvider<LoginBloc>(create: (_) => getIt<LoginBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Fresh Keep Admin',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      ),
    );
  }
}
