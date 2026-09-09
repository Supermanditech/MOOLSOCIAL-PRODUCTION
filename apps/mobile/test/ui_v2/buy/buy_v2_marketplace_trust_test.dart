import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => r66VisualCaptureRoot(child!),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      productId: session.selectedProductId,
    ),
  );

  for (final id in ['s-milk', 'w-notebook']) {
    for (final scale in [1.0, 2.0]) {
      for (final ratingsReady in [true, false]) {
        testWidgets(
          'R669 one seller visit beside identity $id $scale ratings $ratingsReady',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(320, 711);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final core = BuySession();
            final session = BuyV2Session(
              core: core,
              marketplaceTrustAdapter: _TrustAdapter()
                ..available = ratingsReady,
            );
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            expect(session.openProduct(id), isTrue);
            await tester.pumpWidget(app(session));
            await tester.pumpAndSettle();
            final shop =
                session.product(id).destination == BuyV2Destination.shop;
            final label = shop ? 'Visit store' : 'Visit supplier';
            final action = find.byKey(
              ValueKey(
                '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
              ),
            );
            final identity = find.byKey(ValueKey('buy-product-hero-store-$id'));
            final scroll = find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$id')),
                  matching: find.byType(Scrollable),
                )
                .first;
            await tester.scrollUntilVisible(action, 180, scrollable: scroll);
            await Scrollable.ensureVisible(
              tester.element(identity),
              alignment: .2,
            );
            await tester.pumpAndSettle();
            expect(
              find.descendant(of: identity, matching: action),
              findsOneWidget,
            );
            expect(find.text(label), findsOneWidget);
            expect(action.hitTestable(), findsOneWidget);
            expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
            if (ratingsReady) {
              await captureR66Visual(tester, 'r669-seller-$id-$scale');
            }
            await tester.tap(action);
            await tester.pumpAndSettle();
            final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
            expect(find.byKey(ValueKey('$prefix-sheet-$id')), findsOneWidget);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.selectedProductId, id);
            expect(session.view, BuyV2View.product);
            expect(action.hitTestable(), findsOneWidget);
            final trust = find.byKey(
              ValueKey(
                'buy-marketplace-trust-${ratingsReady ? 'ready' : 'offline'}-$id',
              ),
            );
            await tester.scrollUntilVisible(
              trust,
              240,
              maxScrolls: 40,
              scrollable: scroll,
            );
            await tester.pumpAndSettle();
            expect(
              find.descendant(of: trust, matching: find.text(label)),
              findsNothing,
            );
            expect(session.itemCount, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

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
    final product = session.product('s-milk');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-product-hero-store-s-milk')),
        matching: find.textContaining(product.seller),
      ),
      findsOneWidget,
    );
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
    expect(session.marketplaceTrustFor(product).partnerName, product.seller);
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
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
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
