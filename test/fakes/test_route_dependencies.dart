import 'package:fresh_keep_admin/shared/creators/domain/get_creator_label_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_product_details_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_products_usecase.dart';
import 'package:fresh_keep_admin/features/products/domain/usecases/get_receipt_label_usecase.dart';
import 'package:fresh_keep_admin/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:fresh_keep_admin/features/products/presentation/bloc/products_list_bloc.dart';
import 'package:fresh_keep_admin/features/products/presentation/products_list_location.dart';
import 'package:fresh_keep_admin/features/receipts/domain/usecases/get_receipt_details_usecase.dart';
import 'package:fresh_keep_admin/features/receipts/domain/usecases/get_receipts_list_usecase.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/bloc/receipt_detail_bloc.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/bloc/receipts_list_bloc.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/receipts_list_location.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_user_details_usecase.dart';
import 'package:fresh_keep_admin/features/users/domain/usecases/get_users_usecase.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/user_detail_bloc.dart';
import 'package:fresh_keep_admin/features/users/presentation/bloc/users_list_bloc.dart';
import 'package:fresh_keep_admin/features/users/presentation/users_list_location.dart';
import 'package:fresh_keep_admin/routes/route_dependencies.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_products_added_usecase.dart';
import 'package:fresh_keep_admin/shared/metrics/domain/usecases/get_receipts_usecase.dart';

import 'fake_dashboard_repository.dart';
import 'fake_products_repository.dart';
import 'fake_receipts_repository.dart';
import 'fake_users_repository.dart';

/// Route dependencies over fakes, with "today" fixed at [kTestToday].
///
/// [dashboard] also answers the daily metrics behind a user's activity
/// charts.
RouteDependencies testRouteDependencies({
  FakeDashboardRepository? dashboard,
  FakeUsersRepository? users,
  UsersListLocation? usersListLocation,
  FakeProductsRepository? products,
  ProductsListLocation? productsListLocation,
  FakeReceiptsRepository? receipts,
  ReceiptsListLocation? receiptsListLocation,
}) {
  final usersRepository = users ?? FakeUsersRepository();
  final metrics = dashboard ?? FakeDashboardRepository();
  final productsRepository = products ?? FakeProductsRepository();
  final receiptsRepository = receipts ?? FakeReceiptsRepository();
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
    productsListBloc: () => ProductsListBloc(
      getProductsUseCase: GetProductsUseCase(productsRepository),
      getCreatorLabelUseCase: GetCreatorLabelUseCase(productsRepository),
      getReceiptLabelUseCase: GetReceiptLabelUseCase(productsRepository),
      today: () => kTestToday,
    ),
    productDetailBloc: () => ProductDetailBloc(
      getProductDetailsUseCase: GetProductDetailsUseCase(productsRepository),
      today: () => kTestToday,
    ),
    productsListLocation: productsListLocation ?? ProductsListLocation(),
    receiptsListBloc: () => ReceiptsListBloc(
      getReceiptsListUseCase: GetReceiptsListUseCase(receiptsRepository),
      getCreatorLabelUseCase: GetCreatorLabelUseCase(receiptsRepository),
      today: () => kTestToday,
    ),
    receiptDetailBloc: () => ReceiptDetailBloc(
      getReceiptDetailsUseCase: GetReceiptDetailsUseCase(receiptsRepository),
      today: () => kTestToday,
    ),
    receiptsListLocation: receiptsListLocation ?? ReceiptsListLocation(),
  );
}
