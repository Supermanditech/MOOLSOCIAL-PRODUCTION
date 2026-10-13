import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'one Shop root tap returns Wholesale to the existing Shop session',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.openDestination(BuyV2Destination.wholesale);
      final product = session.visibleProducts.first;
      expect(session.addProduct(product.id), isTrue);
      final quantity = session.quantityFor(product.id);
      final cartCount = session.itemCount;

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();
      var notifications = 0;
      void countNotification() => notifications++;
      session.addListener(countNotification);

      await tester.tap(
        find.byKey(const ValueKey('moolsocial-family-root-buy-tap')),
      );
      await tester.pumpAndSettle();

      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(notifications, 1);
      expect(session.itemCount, cartCount);
      expect(session.quantityFor(product.id), quantity);
      expect(find.text('Search products'), findsOneWidget);
      expect(tester.takeException(), isNull);
      session.removeListener(countNotification);
    },
  );

  testWidgets('one Shop root tap closes Offers into the Shop catalogue', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session, initialOffersActive: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Offers'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('moolsocial-family-root-buy-tap')),
    );
    await tester.pumpAndSettle();

    expect(session.destination, BuyV2Destination.shop);
    expect(find.text('Search products'), findsOneWidget);
    expect(find.text('Published prices from trusted sellers'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
