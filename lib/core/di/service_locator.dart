import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_admin_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_product_type_counts_usecase.dart';
import '../../features/dashboard/domain/usecases/get_products_added_usecase.dart';
import '../../features/dashboard/domain/usecases/get_receipts_usecase.dart';
import '../../features/dashboard/domain/usecases/get_user_registrations_usecase.dart';
import '../config/env.dart';
import '../network/dio_client.dart';
import '../network/session_expired_notifier.dart';
import '../storage/session_storage.dart';

final getIt = GetIt.instance;

/// [sessionStorage] is injected rather than built here so that this file
/// never imports `package:web`: `main.dart` passes `WebSessionStorage`, tests
/// pass an in-memory fake.
void setupServiceLocator({
  required SessionStorage sessionStorage,
  String baseUrl = Env.apiBaseUrl,
}) {
  getIt.registerSingleton<SessionStorage>(sessionStorage);
  getIt.registerLazySingleton(SessionExpiredNotifier.new);
  getIt.registerLazySingleton<Dio>(
    () => DioClient(
      baseUrl: baseUrl,
      sessionStorage: getIt(),
      sessionExpiredNotifier: getIt(),
    ).dio,
  );

  getIt.registerLazySingleton(() => AuthRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => AuthLocalDataSource(getIt()));
  getIt.registerLazySingleton<AuthRepository>(
    () =>
        AuthRepositoryImpl(remoteDataSource: getIt(), localDataSource: getIt()),
  );
  getIt.registerFactory(() => LoginUseCase(getIt()));
  getIt.registerFactory(() => GetCurrentAdminUseCase(getIt()));
  getIt.registerFactory(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(
    () => AuthBloc(
      getCurrentAdminUseCase: getIt(),
      logoutUseCase: getIt(),
      sessionExpiredNotifier: getIt(),
    ),
  );
  getIt.registerFactory(
    () => LoginBloc(loginUseCase: getIt(), authBloc: getIt()),
  );

  getIt.registerLazySingleton(() => DashboardRemoteDataSource(getIt()));
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory(() => GetUserRegistrationsUseCase(getIt()));
  getIt.registerFactory(() => GetProductsAddedUseCase(getIt()));
  getIt.registerFactory(() => GetReceiptsUseCase(getIt()));
  getIt.registerFactory(() => GetProductTypeCountsUseCase(getIt()));
}
