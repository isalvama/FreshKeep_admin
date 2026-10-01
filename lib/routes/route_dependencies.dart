import '../core/di/service_locator.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/products/presentation/bloc/product_detail_bloc.dart';
import '../features/products/presentation/bloc/products_list_bloc.dart';
import '../features/products/presentation/products_list_location.dart';
import '../features/users/presentation/bloc/user_detail_bloc.dart';
import '../features/users/presentation/bloc/users_list_bloc.dart';
import '../features/users/presentation/users_list_location.dart';

/// What the routes build their pages with. Defaults to the service locator;
/// tests pass fakes, so the router can be tested without the whole app.
class RouteDependencies {
  final DashboardBloc Function() dashboardBloc;
  final UsersListBloc Function() usersListBloc;
  final UserDetailBloc Function() userDetailBloc;
  final UsersListLocation usersListLocation;
  final ProductsListBloc Function() productsListBloc;
  final ProductDetailBloc Function() productDetailBloc;
  final ProductsListLocation productsListLocation;

  const RouteDependencies({
    required this.dashboardBloc,
    required this.usersListBloc,
    required this.userDetailBloc,
    required this.usersListLocation,
    required this.productsListBloc,
    required this.productDetailBloc,
    required this.productsListLocation,
  });

  factory RouteDependencies.fromServiceLocator() => RouteDependencies(
    dashboardBloc: () => getIt<DashboardBloc>(),
    usersListBloc: () => getIt<UsersListBloc>(),
    userDetailBloc: () => getIt<UserDetailBloc>(),
    usersListLocation: getIt<UsersListLocation>(),
    productsListBloc: () => getIt<ProductsListBloc>(),
    productDetailBloc: () => getIt<ProductDetailBloc>(),
    productsListLocation: getIt<ProductsListLocation>(),
  );
}
