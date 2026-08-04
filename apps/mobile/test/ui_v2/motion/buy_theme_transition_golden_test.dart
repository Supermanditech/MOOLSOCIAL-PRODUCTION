import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  Future<void> capture(
    WidgetTester tester,
    String golden,
    void Function(BuyV2Session session) arrange,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RepaintBoundary(
            key: const ValueKey('buy-theme-review-boundary'),
            child: BuyV2Screen(session: session),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    arrange(session);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('buy-theme-review-boundary')),
      matchesGoldenFile('goldens/$golden.png'),
    );
  }

  testWidgets('Shop theme review', (tester) async {
    await capture(
      tester,
      'buy-theme-shop',
      (session) => session.openDestination(BuyV2Destination.shop),
    );
  });

  testWidgets('Wholesale theme review', (tester) async {
    await capture(
      tester,
      'buy-theme-wholesale',
      (session) => session.openDestination(BuyV2Destination.wholesale),
    );
  });

  testWidgets('Medicine theme review', (tester) async {
    await capture(
      tester,
      'buy-theme-medicine',
      (session) => session.openDestination(BuyV2Destination.medicine),
    );
  });

  testWidgets('Orders theme review', (tester) async {
    await capture(
      tester,
      'buy-theme-orders',
      (session) => session.openOrders(),
    );
  });

  testWidgets('Cart theme review', (tester) async {
    await capture(tester, 'buy-theme-cart', (session) {
      session.addProduct(session.visibleProducts.first.id);
      session.openCart();
    });
  });

  testWidgets('Tracking theme review', (tester) async {
    await capture(
      tester,
      'buy-theme-tracking',
      (session) => session.openTracking('MS-240782'),
    );
  });
}
