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
              find.descendant(
                of: find.byKey(ValueKey('buy-automatic-fulfilment-$id')),
                matching: action,
              ),
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
            // MVP feedback is purchase-linked and private; supplier identity
            // remains usable independently of the retired public score panel.
            for (final state in ['ready', 'offline']) {
              expect(find.byKey(ValueKey('buy-marketplace-trust-$state-$id')),
                  findsNothing);
            }
            expect(find.text('Customer ratings'), findsNothing);
            expect(find.text('4.6 from 328 ratings'), findsNothing);
            expect(find.text(label), findsOneWidget);
            expect(session.itemCount, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('seller facts remain product-specific without public ratings', (
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
    expect(find.byKey(const ValueKey('buy-marketplace-trust-ready-s-milk')),
        findsNothing);
    expect(find.text('Customer ratings'), findsNothing);
    expect(find.text('4.6 from 328 ratings'), findsNothing);
    expect(find.text('301'), findsNothing);
    expect(session.marketplaceTrustFor(product).partnerName, product.seller);
    expect(find.text('4.8'), findsNothing);
    expect(find.text('1842'), findsOneWidget);
    expect(find.text('96% orders delivered as promised'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seller-source recovery does not expose ratings or change Cart', (
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

    final product = session.product('s-milk');
    final total = session.cartTotal;
    expect(session.marketplaceTrustFor(product).state,
        BuyV2MarketplaceTrustState.offline);
    expect(find.byKey(const ValueKey('buy-marketplace-trust-retry-s-milk')),
        findsNothing);
    expect(find.text('Ratings unavailable'), findsNothing);
    expect(find.text('Ratings could not be loaded.'), findsNothing);
    expect(find.text('4.6 from 328 ratings'), findsNothing);

    adapter.available = true;
    expect(session.refreshMarketplaceTrust(product.id), isTrue);
    await tester.pumpAndSettle();
    expect(session.marketplaceTrustFor(product).state,
        BuyV2MarketplaceTrustState.ready);
    expect(
      find.byKey(const ValueKey('buy-marketplace-trust-ready-s-milk')),
      findsNothing,
    );
    expect(find.text('Customer ratings'), findsNothing);
    expect(find.text('4.6 from 328 ratings'), findsNothing);
    expect(session.selectedProductId, product.id);
    expect(session.cartTotal, total);
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
