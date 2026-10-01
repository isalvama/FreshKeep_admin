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
import 'package:fresh_keep_admin/features/receipts/domain/entities/receipt_details.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/pages/receipt_detail_page.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/receipts_list_location.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/widgets/receipt_card.dart';
import 'package:fresh_keep_admin/features/receipts/presentation/widgets/receipt_products_card.dart';
import 'package:fresh_keep_admin/routes/app_router.dart';
import 'package:fresh_keep_admin/shared/metrics/presentation/format.dart';
import 'package:fresh_keep_admin/shared/products/money.dart';
import 'package:fresh_keep_admin/shared/products/widgets/expiration_cell.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_receipts_repository.dart';
import '../../../../fakes/test_route_dependencies.dart';

void main() {
  late FakeReceiptsRepository repository;
  late ReceiptsListLocation listLocation;
  late SessionExpiredNotifier notifier;
  late AuthBloc authBloc;
  late LoginBloc loginBloc;
  late GoRouter router;

  setUp(() {
    repository = FakeReceiptsRepository();
    listLocation = ReceiptsListLocation();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    String location = '/receipts/$kTestReceiptId',
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
        receipts: repository,
        receiptsListLocation: listLocation,
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

  Finder inTotals(String text) => find.descendant(
    of: find.byKey(const Key('receipt-totals')),
    matching: find.text(text),
  );

  ReceiptDetails receiptWith({
    String? storeName = 'SuperMart',
    String? creatorId = kTestReceiptCreatorId,
    String? spaceName = 'Kitchen',
    String? imageMimeType = 'image/jpeg',
    List<ReceiptProduct> products = const [],
  }) => ReceiptDetails(
    id: kTestReceiptId,
    creatorId: creatorId,
    creatorEmail: creatorId == null ? null : 'alice@example.com',
    creatorUsername: creatorId == null ? null : 'alice',
    spaceName: spaceName,
    storeName: storeName,
    purchaseDate: DateTime.utc(2026, 9, 8),
    createdAt: DateTime.utc(2026, 9, 8, 10, 15),
    imageMimeType: imageMimeType,
    products: products,
  );

  testWidgets('requests the receipt in the URL', (tester) async {
    await pumpDetail(tester, location: '/receipts/abc-123');

    expect(repository.detailCalls, ['abc-123']);
  });

  testWidgets('the receipt card shows store, dates, creator, space, image', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('SuperMart'), findsNWidgets(2)); // title and Store
    expect(find.text('Sep 8, 2026'), findsOneWidget);
    expect(
      find.text(formatDateTime(DateTime.utc(2026, 9, 8, 10, 15))),
      findsOneWidget,
    );
    expect(find.text('alice@example.com (alice)'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Image attached (JPEG)'), findsOneWidget);
  });

  testWidgets('missing values show "—" and no image says so', (tester) async {
    repository.details = Right(
      receiptWith(
        storeName: null,
        creatorId: null,
        spaceName: null,
        imageMimeType: null,
      ),
    );
    await pumpDetail(tester);

    expect(find.text('Receipt'), findsOneWidget); // title without a store
    expect(find.text(kMissingValue), findsNWidgets(3)); // store, by, space
    expect(find.text(kNoImage), findsOneWidget);
    expect(find.byKey(const Key('creator-link')), findsNothing);
  });

  testWidgets('lists products oldest first with type, badge and price', (
    tester,
  ) async {
    await pumpDetail(tester);

    final names = ['Milk', 'Bread', 'Cheese', 'Salmon'];
    for (var i = 1; i < names.length; i++) {
      expect(
        tester.getTopLeft(find.text(names[i - 1])).dy,
        lessThan(tester.getTopLeft(find.text(names[i])).dy),
      );
    }
    expect(find.text('Bakery'), findsOneWidget);
    // Today is Oct 1: Milk (Oct 3) expires soon, Bread (Sep 28) expired.
    expect(find.text(kExpiresSoonLabel), findsOneWidget);
    expect(find.text(kExpiredLabel), findsNWidgets(2)); // Bread and Salmon
    expect(find.text('1.50 USD'), findsOneWidget);
  });

  testWidgets('a deleted product is labelled, not clickable, and not in the '
      'total', (tester) async {
    await pumpDetail(tester);

    expect(find.text(kDeletedLabel), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.text('Salmon'));
    await tester.pumpAndSettle();
    expect(location(), '/receipts/$kTestReceiptId');

    // 1.50 + 2.25; Salmon's 9.99 is left out.
    expect(inTotals('Total 3.75 USD'), findsOneWidget);
  });

  testWidgets('counts products without a price', (tester) async {
    await pumpDetail(tester);

    expect(inTotals('1 product without a price'), findsOneWidget);
  });

  testWidgets('one total per currency', (tester) async {
    repository.details = Right(
      receiptWith(
        products: const [
          ReceiptProduct(
            id: 'a',
            name: 'Wine',
            productType: 'BEVERAGES',
            expirationDate: null,
            price: Money(amount: 12, currency: 'EUR'),
            deleted: false,
          ),
          ReceiptProduct(
            id: 'b',
            name: 'Tea',
            productType: 'BEVERAGES',
            expirationDate: null,
            price: Money(amount: 4.5, currency: 'USD'),
            deleted: false,
          ),
        ],
      ),
    );
    await pumpDetail(tester);

    expect(inTotals('Total 12.00 EUR'), findsOneWidget);
    expect(inTotals('Total 4.50 USD'), findsOneWidget);
  });

  testWidgets('an empty receipt says so, without totals', (tester) async {
    repository.details = Right(receiptWith());
    await pumpDetail(tester);

    expect(find.text(kNoProductsOnReceipt), findsOneWidget);
    expect(find.byKey(const Key('receipt-totals')), findsNothing);
  });

  testWidgets('a product row opens its product page', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(location(), '/products/product-1');
  });

  testWidgets('the creator opens their user page', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('creator-link')));
    await tester.pumpAndSettle();

    expect(location(), '/users/$kTestReceiptCreatorId');
  });

  testWidgets('an unknown or malformed id shows "Receipt not found"', (
    tester,
  ) async {
    repository.details = const Left(ValidationFailure('No such receipt.'));
    await pumpDetail(tester, location: '/receipts/nope');

    expect(find.text(kReceiptNotFoundMessage), findsOneWidget);
    expect(find.text('Back to receipts'), findsOneWidget);
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

    repository.details = Right(testReceiptDetails());
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.detailCalls, hasLength(2));
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('"Back to receipts" returns to the last list URL', (
    tester,
  ) async {
    await pumpDetail(tester, location: '/receipts?range=90d&page=2');
    await tester.tap(find.text('Store 030'));
    await tester.pumpAndSettle();
    expect(location(), '/receipts/receipt-30');

    await tester.tap(find.text('Back to receipts'));
    await tester.pumpAndSettle();

    expect(location(), '/receipts?range=90d&page=2');
  });

  testWidgets('at 800px nothing overflows', (tester) async {
    await pumpDetail(tester, size: const Size(800, 1800));

    expect(tester.takeException(), isNull);
    expect(find.text('Milk'), findsOneWidget);
  });
}
