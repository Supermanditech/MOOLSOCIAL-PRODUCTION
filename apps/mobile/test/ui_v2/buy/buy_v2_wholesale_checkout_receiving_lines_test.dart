import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: safeArea,
        viewPadding: safeArea,
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.checkoutScope,
    ),
  );

  BuyV2Session checkout(List<String> ids, {BuyV2CartScope? scope}) {
    final session = BuyV2Session(core: BuySession());
    for (final id in ids) {
      expect(session.addProduct(id), isTrue, reason: id);
    }
    if (scope == null) {
      session.openCart();
    } else {
      session.openCart(scope: scope);
    }
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    expect(session.continueCheckoutFromPayment(), isTrue);
    return session;
  }

  testWidgets('one Wholesale receiving line retains every Cart decision fact', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(
      buyV2WholesaleCheckoutReceivingLinesContractVersion,
      'buy-wholesale-checkout-receiving-lines-v1',
    );
    expect(find.text('Products and trade packs'), findsOneWidget);
    expect(find.text(product.title), findsOneWidget);
    expect(find.text('2 packs · ${product.pack}'), findsOneWidget);
    expect(
      find.text(
        'MOQ ${product.minimumOrder} · '
        '${buyV2Money(product.price)} per pack · ${product.unitPrice}',
      ),
      findsOneWidget,
    );
    expect(find.text('Line subtotal'), findsOneWidget);
    expect(find.text(buyV2Money(product.price * 2)), findsWidgets);
    final line = find.byKey(
      ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
    );
    expect(line, findsOneWidget);
    expect(tester.getSemantics(line).label, contains('2 packs'));
    expect(tester.getSemantics(line).label, contains(product.unitPrice));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple Wholesale products retain independent line subtotals', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion', 'w-potato']);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final id in const ['w-onion', 'w-potato']) {
      final product = session.product(id);
      expect(
        find.byKey(
          ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
        ),
        findsOneWidget,
      );
      expect(find.text(product.title), findsOneWidget);
      expect(find.text(buyV2Money(product.price * 2)), findsWidgets);
    }
    final groups = session.checkoutFulfilmentGroups;
    expect(groups, isNotEmpty);
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final products =
          '${group.lines.length} '
          '${group.lines.length == 1 ? 'product' : 'products'}';
      final packs =
          '${group.itemCount} '
          '${group.itemCount == 1 ? 'pack' : 'packs'}';
      expect(
        find.text('Shipment ${index + 1} · $products · $packs'),
        findsOneWidget,
      );
    }
    expect(groups.fold<int>(0, (total, group) => total + group.itemCount), 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Checkout does not expose Wholesale receiving UI', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['s-tomato'], scope: BuyV2CartScope.shop);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Products and trade packs'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('buy-wholesale-checkout-receiving-line-s-tomato'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('receiving lines remain readable at compact large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        safeArea: const EdgeInsets.symmetric(vertical: 24),
      ),
    );
    await tester.pumpAndSettle();

    final line = find.byKey(
      ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
    );
    await tester.scrollUntilVisible(
      line,
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-checkout-confirm')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(line, findsOneWidget);
    expect(find.text('2 packs · ${product.pack}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
