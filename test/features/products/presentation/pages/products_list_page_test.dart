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
import 'package:fresh_keep_admin/features/products/domain/entities/product_filters.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/product_sort.dart';
import 'package:fresh_keep_admin/features/products/domain/entities/receipt_label.dart';
import 'package:fresh_keep_admin/features/products/presentation/pages/products_list_page.dart';
import 'package:fresh_keep_admin/features/products/presentation/products_list_location.dart';
import 'package:fresh_keep_admin/features/products/presentation/widgets/expiration_cell.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
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

  Future<void> pumpProducts(
    WidgetTester tester, {
    String location = '/products',
  }) async {
    tester.view.physicalSize = const Size(1400, 1800);
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

  String position(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('pagination-position'))).data!;

  IconButton pagerButton(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );

  Future<void> choose(WidgetTester tester, Key dropdown, String item) async {
    await tester.tap(find.byKey(dropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  /// The text shown in a dropdown's field (not its open menu).
  bool dropdownShows(Key dropdown, String text) => find
      .descendant(of: find.byKey(dropdown), matching: find.text(text))
      .evaluate()
      .isNotEmpty;

  group('URL', () {
    testWidgets('/products is replaced with the defaults and requested', (
      tester,
    ) async {
      await pumpProducts(tester);

      expect(location(), '/products?sort=name_asc&page=1');
      expect(repository.listCalls.single, (const ProductFilters(), 1));
    });

    testWidgets('a deep link keeps its sort, filters and page', (tester) async {
      const url =
          '/products?sort=price_desc&type=DAIRY&creatorId=$kTestCreatorId'
          '&receiptId=$kTestReceiptId&page=2';
      await pumpProducts(tester, location: url);

      expect(location(), url);
      expect(repository.listCalls.single, (
        const ProductFilters(
          sort: ProductSort.priceDesc,
          productType: 'DAIRY',
          creatorId: kTestCreatorId,
          receiptId: kTestReceiptId,
        ),
        2,
      ));
    });

    testWidgets('invalid values are dropped one by one, valid ones kept', (
      tester,
    ) async {
      for (final (bad, fixed) in [
        (
          '/products?sort=bogus&type=DAIRY&page=0',
          '/products?sort=name_asc&type=DAIRY&page=1',
        ),
        (
          '/products?creatorId=abc&receiptId=$kTestReceiptId&page=2',
          '/products?sort=name_asc&receiptId=$kTestReceiptId&page=2',
        ),
        (
          '/products?sort=price_asc&type=CHEESE&x=1',
          '/products?sort=price_asc&page=1',
        ),
      ]) {
        await pumpProducts(tester, location: bad);

        expect(location(), fixed, reason: bad);
      }
    });

    testWidgets('remembers the list URL for "Back to products"', (
      tester,
    ) async {
      await pumpProducts(tester, location: '/products?sort=price_asc&page=3');

      expect(listLocation.value, '/products?sort=price_asc&page=3');
    });
  });

  group('controls', () {
    testWidgets('a new sort is written to the URL and resets the page', (
      tester,
    ) async {
      await pumpProducts(tester, location: '/products?sort=name_asc&page=3');

      await choose(tester, const Key('products-sort'), 'Price high–low');

      expect(location(), '/products?sort=price_desc&page=1');
      expect(repository.listCalls.last.$1.sort, ProductSort.priceDesc);
    });

    testWidgets('choosing a type filters by it; All types clears it', (
      tester,
    ) async {
      await pumpProducts(tester, location: '/products?sort=name_asc&page=2');

      await choose(
        tester,
        const Key('products-type'),
        'Ice cream and desserts',
      );
      expect(
        location(),
        '/products?sort=name_asc&type=ICE_CREAM_AND_DESSERTS&page=1',
      );

      await choose(tester, const Key('products-type'), 'All types');
      expect(location(), '/products?sort=name_asc&page=1');
    });

    testWidgets('the dropdowns follow the URL (e.g. browser Back)', (
      tester,
    ) async {
      await pumpProducts(tester);
      expect(dropdownShows(const Key('products-sort'), 'Name A–Z'), isTrue);

      router.go('/products?sort=expiration_date_asc&type=BAKERY&page=1');
      await tester.pumpAndSettle();

      expect(
        dropdownShows(const Key('products-sort'), 'Expires soonest'),
        isTrue,
      );
      expect(dropdownShows(const Key('products-type'), 'Bakery'), isTrue);
    });

    testWidgets('a creator filter shows its email; ✕ removes it', (
      tester,
    ) async {
      await pumpProducts(
        tester,
        location: '/products?sort=name_asc&creatorId=$kTestCreatorId&page=2',
      );

      expect(find.text('Added by alice@example.com'), findsOneWidget);
      expect(repository.creatorCalls, [kTestCreatorId]);

      await tester.tap(find.byTooltip('Remove creator filter'));
      await tester.pumpAndSettle();

      expect(location(), '/products?sort=name_asc&page=1');
      expect(find.byKey(const Key('creator-chip')), findsNothing);
    });

    testWidgets('a receipt filter shows its store and date; ✕ removes it', (
      tester,
    ) async {
      await pumpProducts(
        tester,
        location: '/products?sort=name_asc&receiptId=$kTestReceiptId&page=1',
      );

      expect(find.text('Receipt: SuperMart · Sep 8, 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove receipt filter'));
      await tester.pumpAndSettle();

      expect(location(), '/products?sort=name_asc&page=1');
    });

    testWidgets('a receipt without a store shows just its date', (
      tester,
    ) async {
      repository.receiptLabel = Right(
        ReceiptLabel(storeName: null, purchaseDate: DateTime.utc(2026, 9, 8)),
      );
      await pumpProducts(
        tester,
        location: '/products?sort=name_asc&receiptId=$kTestReceiptId&page=1',
      );

      expect(find.text('Receipt: Sep 8, 2026'), findsOneWidget);
    });

    testWidgets('chips that cannot be labelled show a short id; the list '
        'still loads', (tester) async {
      repository
        ..creatorEmail = const Left(ServerFailure('Something went wrong.'))
        ..receiptLabel = const Left(ServerFailure('Something went wrong.'));
      await pumpProducts(
        tester,
        location:
            '/products?sort=name_asc&creatorId=$kTestCreatorId'
            '&receiptId=$kTestReceiptId&page=1',
      );

      expect(find.text('Added by 3f2a9c1e…'), findsOneWidget);
      expect(find.text('Receipt d5b3e9c2…'), findsOneWidget);
      expect(find.text('Product 000'), findsOneWidget);
    });
  });

  group('table', () {
    testWidgets('shows name, type, expiration and price', (tester) async {
      await pumpProducts(tester);

      expect(find.text('Product 000'), findsOneWidget);
      expect(find.text('Dairy'), findsWidgets);
      expect(find.text('Other fresh products'), findsWidgets);
      expect(find.text('Sep 28, 2026'), findsWidgets);
      expect(find.text('1.50 USD'), findsOneWidget);
      // Rows 0–29: every 4th from row 2 has no expiration date, every 4th
      // from row 3 has no price (7 each).
      expect(find.text('—'), findsNWidgets(7 + 7));
    });

    testWidgets('badges pair a label with an icon, never color alone', (
      tester,
    ) async {
      await pumpProducts(tester);

      // Today is Oct 1: Sep 28 is expired, Oct 3 expires soon, Nov 20 is fine.
      expect(find.text(kExpiredLabel), findsNWidgets(8));
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(8));
      expect(find.text(kExpiresSoonLabel), findsNWidgets(8));
      expect(find.byIcon(Icons.schedule), findsNWidgets(8));
      expect(find.byType(ExpirationBadge), findsNWidgets(16));
    });

    testWidgets('clicking a row opens that product', (tester) async {
      await pumpProducts(tester);

      await tester.tap(find.text('Product 001'));
      await tester.pumpAndSettle();

      expect(location(), '/products/product-1');
    });
  });

  group('paging', () {
    testWidgets('page 1 shows Products 1–30 with Previous disabled', (
      tester,
    ) async {
      await pumpProducts(tester);

      expect(position(tester), 'Products 1–30');
      expect(pagerButton(tester, 'Previous page').onPressed, isNull);
      expect(pagerButton(tester, 'Next page').onPressed, isNotNull);
    });

    testWidgets('Next moves to page 2, keeping the filters', (tester) async {
      await pumpProducts(tester, location: '/products?sort=price_asc&page=1');

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(location(), '/products?sort=price_asc&page=2');
      expect(position(tester), 'Products 31–60');
    });

    testWidgets('a short page is the last: Next is disabled', (tester) async {
      await pumpProducts(tester, location: '/products?sort=name_asc&page=3');

      expect(position(tester), 'Products 61–75');
      expect(pagerButton(tester, 'Next page').onPressed, isNull);
    });

    testWidgets('an empty page past the end offers the first page', (
      tester,
    ) async {
      await pumpProducts(
        tester,
        location: '/products?sort=name_asc&type=DAIRY&page=9',
      );

      expect(find.text(kNoMoreProductsMessage), findsOneWidget);

      await tester.tap(find.text('Go to first page'));
      await tester.pumpAndSettle();

      expect(location(), '/products?sort=name_asc&type=DAIRY&page=1');
    });
  });

  group('states', () {
    testWidgets('nothing matching shows the empty message', (tester) async {
      repository.productsPage = (_, page) =>
          Right(testProductsPage(page: page, total: 0));
      await pumpProducts(tester);

      expect(find.text(kNoProductsMessage), findsOneWidget);
      expect(find.text('Go to first page'), findsNothing);
    });

    testWidgets('a failure shows its message, and Retry reloads the page', (
      tester,
    ) async {
      repository.productsPage = (_, _) => const Left(
        NetworkFailure('Could not reach the server. Please try again.'),
      );
      await pumpProducts(tester, location: '/products?sort=name_asc&page=2');

      expect(
        find.text('Could not reach the server. Please try again.'),
        findsOneWidget,
      );

      repository.productsPage = (_, page) =>
          Right(testProductsPage(page: page));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.listCalls, hasLength(2));
      expect(repository.listCalls.last.$2, 2);
      expect(position(tester), 'Products 31–60');
    });
  });

  testWidgets('at 800px the controls wrap and the table scrolls', (
    tester,
  ) async {
    await pumpProducts(
      tester,
      location:
          '/products?sort=name_asc&creatorId=$kTestCreatorId'
          '&receiptId=$kTestReceiptId&page=1',
    );
    tester.view.physicalSize = const Size(800, 1800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Product 000'), findsOneWidget);
    expect(find.text('Receipt: SuperMart · Sep 8, 2026'), findsOneWidget);
  });
}
