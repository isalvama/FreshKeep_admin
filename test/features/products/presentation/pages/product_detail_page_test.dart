import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/core/network/session_expired_notifier.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/login_usecase.dart';
import 'package:fresh_keep_admin/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fresh_keep_admin/features/auth/presentation/bloc/login_bloc.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_details.dart';
import 'package:fresh_keep_admin/features/products/presentation/pages/product_detail_page.dart';
import 'package:fresh_keep_admin/features/products/presentation/products_list_location.dart';
import 'package:fresh_keep_admin/shared/products/widgets/expiration_cell.dart';
import 'package:fresh_keep_admin/features/products/presentation/widgets/product_origin_card.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/format.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_products_repository.dart';
import '../../../../fakes/test_route_dependencies.dart';

void main() {
  late FakeProductsRepository repository;
  late ProductsListLocation listLocation;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  setUp(() {
    repository = FakeProductsRepository();
    listLocation = ProductsListLocation();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    String location = '/products/product-1',
    Size size = const Size(1400, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authRepository = FakeAuthRepository(storedAdmin: kTestAdmin);
    notifier = SessionExpiredNotifier();
    authBloc = AuthBloc(
      getCurrentAdminUseCase: GetCurrentAdminUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      sessionExpiredNotifier: notifier,
    )..add(const AppStarted());
    loginBloc = LoginBloc(
      loginUseCase: LoginUseCase(authRepository),
      authBloc: authBloc,
    );
    router = buildAppRouter(
      authBloc,
      initialLocation: location,
      dependencies: testRouteDependencies(
        products: repository,
        productsListLocation: listLocation,
      ),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: loginBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    router.dispose();
    await loginBloc.close();
    await authBloc.close();
    await notifier.dispose();
  });

  String location() =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('requests the product in the URL', (tester) async {
    await pumpDetail(tester, location: '/products/abc-123');

    expect(repository.detailCalls, ['abc-123']);
  });

  testWidgets('the product card shows type, expiration, price, spot and '
      'added time', (tester) async {
    await pumpDetail(tester);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Dairy'), findsOneWidget);
    // Oct 3 is two days after "today" (Oct 1).
    expect(find.text('Oct 3, 2026'), findsOneWidget);
    expect(find.text(kExpiresSoonLabel), findsOneWidget);
    expect(find.text('2.50 USD'), findsOneWidget);
    expect(find.text('Fridge'), findsOneWidget);
    expect(
      find.text(formatDateTime(DateTime.utc(2026, 9, 8, 10, 15))),
      findsOneWidget,
    );
  });

  testWidgets('the origin card shows creator, space, store and purchase', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('alice@example.com (alice)'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('SuperMart'), findsOneWidget);
    expect(find.text('Sep 8, 2026'), findsOneWidget);
    expect(find.text(kOtherProductsOnReceipt), findsOneWidget);
  });

  testWidgets('missing values show "—"', (tester) async {
    repository.details = Right(
      ProductDetails(
        id: 'product-1',
        name: 'Mystery jar',
        productType: 'OTHER',
        expirationDate: null,
        storageSpotType: null,
        price: null,
        createdAt: DateTime.utc(2026, 9, 8),
        origin: const ProductOrigin(
          receiptId: kTestReceiptId,
          creatorId: null,
          creatorEmail: null,
          creatorUsername: null,
          spaceName: null,
          storeName: null,
          purchaseDate: null,
        ),
      ),
    );
    await pumpDetail(tester);

    // Expires, price, stored in; creator, space, store, purchased.
    expect(find.text(kMissingValue), findsNWidgets(7));
    expect(find.byKey(const Key('creator-link')), findsNothing);
  });

  testWidgets('a product without a receipt says so', (tester) async {
    repository.details = Right(testProductDetails(withOrigin: false));
    await pumpDetail(tester);

    expect(find.text(kNoReceiptMessage), findsOneWidget);
    expect(find.text(kOtherProductsOnReceipt), findsNothing);
  });

  testWidgets('the creator opens their user page', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('creator-link')));
    await tester.pumpAndSettle();

    expect(location(), '/users/$kTestCreatorId');
  });

  testWidgets('"Other products on this receipt" opens the filtered list', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.tap(find.text(kOtherProductsOnReceipt));
    await tester.pumpAndSettle();

    expect(
      location(),
      '/products?sort=name_asc&receiptId=$kTestReceiptId&page=1',
    );
    expect(find.text('Receipt: SuperMart · Sep 8, 2026'), findsOneWidget);
  });

  testWidgets('an unknown or malformed id shows "Product not found"', (
    tester,
  ) async {
    repository.details = const Left(
      ValidationFailure('Product with id nope does not exist.'),
    );
    await pumpDetail(tester, location: '/products/nope');

    expect(find.text(kProductNotFoundMessage), findsOneWidget);
    expect(find.text('Back to products'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a failure shows its message, and Retry reloads', (tester) async {
    repository.details = const Left(
      NetworkFailure('Could not reach the server. Please try again.'),
    );
    await pumpDetail(tester);

    expect(
      find.text('Could not reach the server. Please try again.'),
      findsOneWidget,
    );

    repository.details = Right(testProductDetails());
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.detailCalls, hasLength(2));
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('"Back to products" returns to the last list URL', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      location: '/products?sort=price_desc&type=DAIRY&page=2',
    );
    await tester.tap(find.text('Product 030'));
    await tester.pumpAndSettle();
    expect(location(), '/products/product-30');

    await tester.tap(find.text('Back to products'));
    await tester.pumpAndSettle();

    expect(location(), '/products?sort=price_desc&type=DAIRY&page=2');
    expect(listLocation.value, '/products?sort=price_desc&type=DAIRY&page=2');
  });

  testWidgets('at 800px the cards stack without overflowing', (tester) async {
    await pumpDetail(tester, size: const Size(800, 1800));

    expect(tester.takeException(), isNull);
    final product = tester.getTopLeft(find.text('Milk'));
    final origin = tester.getTopLeft(find.text('Origin'));
    expect(origin.dy, greaterThan(product.dy));
    expect(origin.dx, product.dx);
  });
}
