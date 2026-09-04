import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session, {required Size size, double textScale = 1}) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: BuyV2ProductView(session: session)),
      ),
    );
  }

  testWidgets('Shop surfaces decision-critical facts before the full table', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.shop,
    );
    session.openProduct(product.id);

    await tester.pumpWidget(app(session, size: const Size(360, 800)));
    await tester.pumpAndSettle();

    final glance = find.byKey(
      ValueKey('buy-product-decision-glance-${product.id}'),
    );
    final buyerPromise = buyV2BuyerDeliveryPromise(
      session.productFactsFor(product),
    );
    expect(glance, findsOneWidget);
    expect(find.text(buyV2Money(product.price)), findsWidgets);
    expect(find.text('Available now'), findsWidgets);
    expect(find.text('${product.pack} · $buyerPromise'), findsOneWidget);
    expect(
      find.descendant(
        of: glance,
        matching: find.text('Fulfilment arranged by MoolSocial'),
      ),
      findsOneWidget,
    );
    expect(find.text('Automatic Mool Partner assignment'), findsNothing);
    expect(tester.getRect(glance).bottom, lessThan(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact large text keeps the decision glance whole', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.shop,
    );
    session.openProduct(product.id);

    await tester.pumpWidget(
      app(session, size: const Size(320, 568), textScale: 1.4),
    );
    await tester.pumpAndSettle();

    final glance = find.byKey(
      ValueKey('buy-product-decision-glance-${product.id}'),
    );
    expect(glance, findsOneWidget);
    expect(tester.getSize(glance).width, greaterThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale retains its dedicated trade decision owner', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.wholesale,
    );
    session.openProduct(product.id);

    await tester.pumpWidget(app(session, size: const Size(360, 800)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('buy-product-decision-glance-${product.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-trade-decision-${product.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
