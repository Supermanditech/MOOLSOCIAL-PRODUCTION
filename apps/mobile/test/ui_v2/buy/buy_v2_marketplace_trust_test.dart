import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      productId: session.selectedProductId,
    ),
  );

  testWidgets('verified ratings and seller facts remain product-specific', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final core = BuySession();
    final adapter = _TrustAdapter();
    final session = BuyV2Session(core: core, marketplaceTrustAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final panel = find.byKey(
      const ValueKey('buy-marketplace-trust-ready-s-milk'),
    );
    await tester.scrollUntilVisible(
      panel,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Ratings and seller'), findsOneWidget);
    expect(find.text('4.6 from 328 ratings'), findsOneWidget);
    expect(find.text('301'), findsOneWidget);
    expect(find.text('Family Dairy & Bake'), findsWidgets);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('1842'), findsOneWidget);
    expect(find.text('96% orders delivered as promised'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ratings recovery never fabricates trust or changes Cart', (
    tester,
  ) async {
    final core = BuySession();
    final adapter = _TrustAdapter()..available = false;
    final session = BuyV2Session(core: core, marketplaceTrustAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final retry = find.byKey(
      const ValueKey('buy-marketplace-trust-retry-s-milk'),
    );
    await tester.scrollUntilVisible(
      retry,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Ratings unavailable'), findsOneWidget);
    expect(find.text('Ratings could not be loaded.'), findsOneWidget);
    expect(find.text('4.6 from 328 ratings'), findsNothing);

    adapter.available = true;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-marketplace-trust-ready-s-milk')),
      findsOneWidget,
    );
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

final class _TrustAdapter implements BuyV2MarketplaceTrustAdapter {
  bool available = true;

  @override
  BuyV2MarketplaceTrustSnapshot snapshotFor(BuyV2Product product) {
    if (!available) {
      return BuyV2MarketplaceTrustSnapshot(
        productId: product.id,
        state: BuyV2MarketplaceTrustState.offline,
        sourceId: 'marketplace-trust-test',
        partnerName: product.seller,
        partnerType: product.partnerRole,
        customerMessage: 'Ratings could not be loaded.',
      );
    }
    return BuyV2MarketplaceTrustSnapshot(
      productId: product.id,
      state: BuyV2MarketplaceTrustState.ready,
      sourceId: 'marketplace-trust-test',
      partnerName: product.seller,
      partnerType: product.partnerRole,
      productRating: 4.6,
      productRatingCount: 328,
      verifiedBuyerRatingCount: 301,
      partnerRating: 4.8,
      partnerOrderCount: 1842,
      partnerLocation: 'Sardarpura, Jodhpur',
      serviceReliabilityLabel: '96% orders delivered as promised',
      returnSummary: product.returnPolicy,
    );
  }
}
