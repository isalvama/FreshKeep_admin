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
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/products/data/datasources/products_remote_datasource.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';
import '../../features/products/domain/usecases/get_product_details_usecase.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/domain/usecases/get_receipt_label_usecase.dart';
import '../../features/products/presentation/bloc/product_detail_bloc.dart';
import '../../features/products/presentation/bloc/products_list_bloc.dart';
import '../../features/products/presentation/products_list_location.dart';
import '../../features/receipts/data/datasources/receipts_remote_datasource.dart';
import '../../features/receipts/data/repositories/receipts_repository_impl.dart';
import '../../features/receipts/domain/repositories/receipts_repository.dart';
import '../../features/receipts/domain/usecases/get_receipt_details_usecase.dart';
import '../../features/receipts/domain/usecases/get_receipts_list_usecase.dart';
import '../../features/receipts/presentation/receipts_list_location.dart';
import '../../features/users/data/datasources/users_remote_datasource.dart';
import '../../features/users/data/repositories/users_repository_impl.dart';
import '../../features/users/domain/repositories/users_repository.dart';
import '../../features/users/domain/usecases/get_user_details_usecase.dart';
import '../../features/users/domain/usecases/get_users_usecase.dart';
import '../../features/users/presentation/bloc/user_detail_bloc.dart';
import '../../features/users/presentation/bloc/users_list_bloc.dart';
import '../../features/users/presentation/users_list_location.dart';
import '../../shared/creators/data/creator_label_remote_datasource.dart';
import '../../shared/creators/data/creator_label_repository_impl.dart';
import '../../shared/creators/domain/creator_label_repository.dart';
import '../../shared/creators/domain/get_creator_label_usecase.dart';
import '../../shared/metrics/data/datasources/metrics_remote_datasource.dart';
import '../../shared/metrics/data/repositories/metrics_repository_impl.dart';
import '../../shared/metrics/domain/repositories/metrics_repository.dart';
import '../../shared/metrics/domain/usecases/get_products_added_usecase.dart';
import '../../shared/metrics/domain/usecases/get_receipts_usecase.dart';
import '../../shared/metrics/domain/usecases/get_user_registrations_usecase.dart';
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

  // Shared daily metrics (dashboard, user activity).
  getIt.registerLazySingleton(() => MetricsRemoteDataSource(getIt()));
  getIt.registerLazySingleton<MetricsRepository>(
    () => MetricsRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => DashboardRemoteDataSource(getIt()));
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory(() => GetUserRegistrationsUseCase(getIt()));
  getIt.registerFactory(() => GetProductsAddedUseCase(getIt()));
  getIt.registerFactory(() => GetReceiptsUseCase(getIt()));
  getIt.registerFactory(() => GetProductTypeCountsUseCase(getIt()));
  getIt.registerFactory(
    () => DashboardBloc(
      getUserRegistrationsUseCase: getIt(),
      getProductsAddedUseCase: getIt(),
      getReceiptsUseCase: getIt(),
      getProductTypeCountsUseCase: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => UsersRemoteDataSource(getIt()));
  getIt.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory(() => GetUsersUseCase(getIt()));
  getIt.registerFactory(() => GetUserDetailsUseCase(getIt()));
  getIt.registerLazySingleton(UsersListLocation.new);
  getIt.registerFactory(() => UsersListBloc(getUsersUseCase: getIt()));
  getIt.registerFactory(
    () => UserDetailBloc(
      getUserDetailsUseCase: getIt(),
      getProductsAddedUseCase: getIt(),
      getReceiptsUseCase: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => CreatorLabelRemoteDataSource(getIt()));
  getIt.registerLazySingleton<CreatorLabelRepository>(
    () => CreatorLabelRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory(() => GetCreatorLabelUseCase(getIt()));

  getIt.registerLazySingleton(() => ProductsRemoteDataSource(getIt()));
  getIt.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory(() => GetProductsUseCase(getIt()));
  getIt.registerFactory(() => GetProductDetailsUseCase(getIt()));
  getIt.registerFactory(() => GetReceiptLabelUseCase(getIt()));
  getIt.registerLazySingleton(ProductsListLocation.new);
  getIt.registerFactory(
    () => ProductsListBloc(
      getProductsUseCase: getIt(),
      getCreatorLabelUseCase: getIt(),
      getReceiptLabelUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ProductDetailBloc(getProductDetailsUseCase: getIt()),
  );

  getIt.registerLazySingleton(() => ReceiptsRemoteDataSource(getIt()));
  getIt.registerLazySingleton<ReceiptsRepository>(
    () => ReceiptsRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory(() => GetReceiptsListUseCase(getIt()));
  getIt.registerFactory(() => GetReceiptDetailsUseCase(getIt()));
  getIt.registerLazySingleton(ReceiptsListLocation.new);
}
