import 'package:fresh_keep_admin/features/users/domain/usecases/get_user_details_usecase.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_users_usecase.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/user_detail_bloc.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/users_list_bloc.dart';
import 'package:fresh_keep_admin/features/users/presentation/users_list_location.dart';
import 'package:fresh_keep_admin/routes/route_dependencies.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_products_added_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_receipts_usecase.dart';

import 'fake_dashboard_repository.dart';
import 'fake_users_repository.dart';

/// Route dependencies over fakes, with "today" fixed at [kTestToday].
///
/// [dashboard] also answers the daily metrics behind a user's activity
/// charts.
RouteDependencies testRouteDependencies({
  FakeDashboardRepository? dashboard,
  FakeUsersRepository? users,
  UsersListLocation? usersListLocation,
}) {
  final usersRepository = users ?? FakeUsersRepository();
  final metrics = dashboard ?? FakeDashboardRepository();
  return RouteDependencies(
    dashboardBloc: () => buildTestDashboardBloc(repository: metrics),
    usersListBloc: () => UsersListBloc(
      getUsersUseCase: GetUsersUseCase(usersRepository),
      today: () => kTestToday,
    ),
    userDetailBloc: () => UserDetailBloc(
      getUserDetailsUseCase: GetUserDetailsUseCase(usersRepository),
      getProductsAddedUseCase: GetProductsAddedUseCase(metrics),
      getReceiptsUseCase: GetReceiptsUseCase(metrics),
      today: () => kTestToday,
    ),
    usersListLocation: usersListLocation ?? UsersListLocation(),
  );
}
