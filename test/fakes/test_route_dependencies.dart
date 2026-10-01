import 'package:fresh_keep_admin/features/users/domain/usecases/get_users_usecase.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/users_list_bloc.dart';
import 'package:fresh_keep_admin/features/users/presentation/users_list_location.dart';
import 'package:fresh_keep_admin/routes/route_dependencies.dart';

import 'fake_dashboard_repository.dart';
import 'fake_users_repository.dart';

/// Route dependencies over fakes, with "today" fixed at [kTestToday].
RouteDependencies testRouteDependencies({
  FakeDashboardRepository? dashboard,
  FakeUsersRepository? users,
  UsersListLocation? usersListLocation,
}) {
  final usersRepository = users ?? FakeUsersRepository();
  return RouteDependencies(
    dashboardBloc: () => buildTestDashboardBloc(repository: dashboard),
    usersListBloc: () => UsersListBloc(
      getUsersUseCase: GetUsersUseCase(usersRepository),
      today: () => kTestToday,
    ),
    usersListLocation: usersListLocation ?? UsersListLocation(),
  );
}
