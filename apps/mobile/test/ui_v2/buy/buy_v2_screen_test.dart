import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: BuyV2Screen(session: session),
    );
  }

  testWidgets('persistent dock keeps every Buy destination visible', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final label in [
      'Mool',
      'Shop',
      'Wholesale',
      'Medicine',
      'Orders',
      'Chat',
    ]) {
      expect(
        find.byKey(ValueKey('buy-dock-${label.toLowerCase()}')),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const ValueKey('buy-dock-wholesale')));
    await tester.pumpAndSettle();
    expect(find.text('Wholesale prices'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-dock-medicine')));
    await tester.pumpAndSettle();
    expect(find.text('Medicines & health'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-wholesale')), findsOneWidget);
  });

  testWidgets(
    'approved Buy shell fits representative small and large devices',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      final session = BuyV2Session(core: BuySession());

      for (final size in const [
        Size(320, 568),
        Size(360, 640),
        Size(360, 800),
        Size(375, 667),
        Size(384, 854),
        Size(390, 844),
        Size(393, 852),
        Size(412, 915),
        Size(430, 932),
        Size(480, 960),
        Size(600, 960),
        Size(768, 1024),
        Size(844, 390),
        Size(932, 430),
        Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'viewport $size');
        expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);
        expect(find.byKey(const ValueKey('buy-dock-orders')), findsOneWidget);
      }
    },
  );

  testWidgets('140 percent text keeps navigation reachable', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: app(session),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('buy-dock-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-wholesale')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-orders')), findsOneWidget);
  });

  testWidgets('critical Buy journeys fit compact and large phone widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      tester.view.physicalSize = size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );

      for (final action in <VoidCallback>[
        () => session.openDestination(BuyV2Destination.wholesale),
        () => session.openDestination(BuyV2Destination.medicine),
        () => session.openProduct(shop.id),
        () {
          session.addProduct(shop.id);
          session.addProduct(wholesale.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
        session.openCheckout,
        session.openOrders,
        () => session.openTracking('MS-240782'),
        session.openAssist,
      ]) {
        action();
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'critical Buy view at $size',
        );
        expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);
      }
    }
  });

  testWidgets('product detail exposes purchase decision information', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(product.title), findsOneWidget);
    expect(find.text('Pack, delivery and seller'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wholesale terms'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Wholesale terms'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Add to cart'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Add to cart'), findsOneWidget);
  });

  testWidgets('add confirmation uses only the compact cart indicator', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );

    session.addProduct(product.id);
    await tester.pump();

    expect(session.notice, isNotNull);
    expect(find.text(session.notice!), findsOneWidget);
  });

  testWidgets('cart item count uses correct singular and plural copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where((item) => item.destination == BuyV2Destination.shop)
        .take(2)
        .toList();
    session.addProduct(products.first.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openCart();
    await tester.pumpAndSettle();

    expect(find.textContaining('1 product ·'), findsOneWidget);
    expect(find.textContaining('1 products'), findsNothing);

    session.addProduct(products.last.id);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 products ·'), findsOneWidget);
  });

  testWidgets('Orders opens at the top after Checkout was scrolled', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-dock-orders')));
    await tester.pumpAndSettle();

    expect(find.text('PURCHASES AND DELIVERY'), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets('saved and product-code header actions complete visibly', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved products'), findsOneWidget);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);

    session.returnToCatalogue();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Find by product code'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Barcode or product code'),
      'atta',
    );
    await tester.tap(find.text('Find product'));
    await tester.pumpAndSettle();

    expect(session.query, 'atta');
  });
}
