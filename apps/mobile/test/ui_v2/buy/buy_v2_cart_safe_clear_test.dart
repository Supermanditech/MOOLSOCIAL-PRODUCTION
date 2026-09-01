import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({BuySession core, BuyV2Session session})> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    return (core: core, session: session);
  }

  testWidgets(
    'Shop clear requires confirmation and preserves Wholesale items',
    (tester) async {
      final fixture = await mount(tester);
      final session = fixture.session;
      expect(session.addProduct('s-tomato'), isTrue);
      expect(session.addProduct('w-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-cart-empty')));
      await tester.pumpAndSettle();
      expect(find.text('Remove Shop items?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-cart-clear-sheet')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-cart-clear-cancel')));
      await tester.pumpAndSettle();
      expect(session.quantityFor('s-tomato'), greaterThan(0));
      expect(session.quantityFor('w-tomato'), greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('buy-cart-empty')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-cart-clear-confirm')));
      await tester.pumpAndSettle();

      expect(session.quantityFor('s-tomato'), 0);
      expect(session.quantityFor('w-tomato'), greaterThan(0));
      expect(session.view, BuyV2View.cart);
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(find.byKey(const ValueKey('buy-cart-clear-sheet')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('All-cart clear changes nothing until the customer confirms', (
    tester,
  ) async {
    final fixture = await mount(tester);
    final session = fixture.session;
    expect(session.addProduct('s-tomato'), isTrue);
    expect(session.addProduct('w-tomato'), isTrue);
    session.openCart();
    await tester.pumpAndSettle();
    final originalCount = session.itemCount;

    await tester.tap(find.byKey(const ValueKey('buy-cart-empty')));
    await tester.pumpAndSettle();
    expect(find.text('Empty entire Cart?'), findsOneWidget);
    expect(session.itemCount, originalCount);

    await tester.tap(find.byKey(const ValueKey('buy-cart-clear-confirm')));
    await tester.pumpAndSettle();
    expect(session.itemCount, 0);
    expect(session.view, BuyV2View.catalogue);
    expect(session.cartScope, BuyV2CartScope.all);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'payment resolution blocks clear without opening a destructive sheet',
    (tester) async {
      final fixture = await mount(tester);
      final session = fixture.session;
      expect(session.addProduct('s-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      session.checkoutSubmissionState =
          BuyV2CheckoutSubmissionState.paymentPending;
      session.notifyListeners();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-cart-empty')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-cart-clear-sheet')), findsNothing);
      expect(session.itemCount, 1);
      expect(
        session.notice,
        'Check the current payment before changing your Cart or payment method.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('clear confirmation keeps both actions usable at large text', (
    tester,
  ) async {
    final fixture = await mount(
      tester,
      size: const Size(320, 568),
      textScale: 1.4,
    );
    final session = fixture.session;
    expect(session.addProduct('w-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-cart-empty')));
    await tester.pumpAndSettle();
    final cancel = find.byKey(const ValueKey('buy-cart-clear-cancel'));
    final confirm = find.byKey(const ValueKey('buy-cart-clear-confirm'));
    expect(tester.getSize(cancel).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(confirm).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}
