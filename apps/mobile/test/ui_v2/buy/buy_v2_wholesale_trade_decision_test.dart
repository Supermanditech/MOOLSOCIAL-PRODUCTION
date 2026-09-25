import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> reveal(
    WidgetTester tester,
    BuyV2Product product,
    Finder target, {
    double delta = 180,
  }) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        delta,
        scrollable: find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${product.id}')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    } else {
      await tester.ensureVisible(target);
    }
    // Loading-state assertions deliberately keep the progress indicator active.
    await tester.pump();
  }

  Widget app(
    BuyV2Session session,
    BuyV2WholesaleTradeDecisionAdapter adapter, {
    Size size = const Size(390, 844),
    double textScale = 1,
    EdgeInsets padding = EdgeInsets.zero,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: padding,
        viewPadding: padding,
        disableAnimations: true,
      ),
      child: r66VisualCaptureRoot(child!),
    ),
    home: BuyV2Screen(
      session: session,
      initialDestination: BuyV2Destination.wholesale,
      initialView: BuyV2View.product,
      productId: 'w-onion',
      wholesaleTradeDecisionAdapter: adapter,
    ),
  );

  BuyV2ProductFactsSnapshot factsFor(
    BuyV2Product product, {
    String orderabilityLabel = 'Available to add',
    bool stale = false,
  }) => BuyV2ProductFactsSnapshot(
    productId: product.id,
    price: product.price,
    deliveryPromise: product.deliveryPromise,
    partner: product.seller,
    orderabilityLabel: orderabilityLabel,
    sourceId: 'wholesale-trade-decision-test',
    stale: stale,
  );

  BuyV2WholesaleTradeSignal readySignal(
    String productId,
  ) => BuyV2WholesaleTradeSignal(
    productId: productId,
    state: BuyV2WholesaleTradeSignalState.ready,
    localityLabel: 'Jodhpur',
    headline: 'Steady local restocking',
    detail:
        'Retailer demand stayed within its usual 7-day range for this trade pack.',
    sourceLabel: 'MoolSocial local trade activity',
    updatedLabel: 'Updated 10 minutes ago',
    priceValidUntilLabel: 'Current through 6:00 pm today',
  );

  testWidgets('ready trade decision leads with MOQ, total and genuine signal', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      productFactsAdapter: _FactsAdapter(factsFor),
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final adapter = _TradeAdapter((productId) async => readySignal(productId));
    final product = session.product('w-onion');

    await tester.pumpWidget(app(session, adapter));
    await tester.pumpAndSettle();

    expect(
      buyV2WholesaleTradeDecisionContractVersion,
      'buy-wholesale-trade-decision-v1',
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-price-summary-${product.id}')),
      findsOneWidget,
    );
    expect(find.text(buyV2Money(product.price)), findsWidgets);
    expect(
      find.textContaining('Minimum ${product.minimumOrder} packs'),
      findsWidgets,
    );
    expect(
      find.text(
        'Minimum ${product.minimumOrder} packs · ${buyV2Money(product.price * product.minimumOrder)}',
      ),
      findsOneWidget,
    );
    await reveal(tester, product, find.text('Jodhpur market insight'));
    expect(find.text('Jodhpur market insight'), findsOneWidget);
    expect(find.text('Steady local restocking'), findsOneWidget);
    expect(
      find.text('MoolSocial local trade activity · Updated 10 minutes ago'),
      findsOneWidget,
    );
    expect(find.text('Current through 6:00 pm today'), findsOneWidget);
    await reveal(
      tester,
      product,
      find.textContaining(product.seller).first,
      delta: -180,
    );
    expect(find.textContaining(product.seller), findsWidgets);

    final gallery = find.byKey(ValueKey('buy-product-packshot-${product.id}'));
    final imageViewport = find.byKey(
      ValueKey('buy-product-gallery-${product.id}'),
    );
    await reveal(tester, product, imageViewport, delta: -180);
    expect(tester.getSize(imageViewport).height, closeTo(280, .1));
    expect(
      tester.getRect(imageViewport).bottom,
      lessThanOrEqualTo(tester.getRect(gallery).bottom),
    );
    expect(
      find.byKey(ValueKey('buy-product-action-save-${product.id}')),
      findsOneWidget,
    );
    await captureR66Visual(tester, 'r669-trade-gallery-and-decision');
    final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    await reveal(tester, product, add);
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    final facts = session.productFactsFor(product);
    final deliveryDecision =
        '${buyV2FulfilmentModeLabel(session.fulfilmentModeFor(product))} · '
        '${buyV2BuyerDeliveryPromise(facts)}';
    expect(
      find.byKey(ValueKey('buy-product-inline-action-${product.id}')),
      findsOneWidget,
    );
    expect(find.textContaining(buyV2BuyerDeliveryPromise(facts)), findsWidgets);
    final actionLabel =
        'Add minimum order of ${product.minimumOrder} packs of '
        '${product.title} to Cart for '
        '${buyV2Money(product.price * product.minimumOrder)}. '
        '$deliveryDecision';
    final actionSemantics = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == actionLabel,
      description: 'Wholesale minimum-order action semantics',
    );
    expect(actionSemantics, findsOneWidget);
    expect(
      tester
          .getSemantics(actionSemantics)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    tester.semantics.tap(find.semantics.byLabel(actionLabel));
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), product.minimumOrder);
    expect(
      find.byKey(ValueKey('buy-product-quantity-${product.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('buy-product-quantity-${product.id}')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    expect(session.quantityFor(product.id), product.minimumOrder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing optional signal stays hidden and does not block trade', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      productFactsAdapter: _FactsAdapter(factsFor),
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(
      app(session, const BuyV2UnavailableWholesaleTradeDecisionAdapter()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local market insight unavailable'), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-wholesale-trade-signal-retry')),
      findsNothing,
    );
    expect(find.textContaining('retailers bought'), findsNothing);
    await reveal(tester, product, find.text(product.confirmedOn));
    expect(find.text(product.confirmedOn), findsOneWidget);
    await reveal(
      tester,
      product,
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      delta: -180,
    );
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsOneWidget,
    );
    await reveal(
      tester,
      product,
      find.byKey(ValueKey('buy-product-hero-store-${product.id}')),
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('buy-product-hero-store-${product.id}')),
        matching: find.textContaining(
          product.customerSeller(session.productFactsFor(product).partner),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and adapter failure retain current trade facts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      productFactsAdapter: _FactsAdapter(factsFor),
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final pending = Completer<BuyV2WholesaleTradeSignal>();
    final adapter = _TradeAdapter((_) => pending.future);
    final product = session.product('w-onion');

    await tester.pumpWidget(app(session, adapter));
    await tester.pump();
    await reveal(tester, product, find.text('Checking local market insight'));
    expect(find.text('Checking local market insight'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reveal(
      tester,
      product,
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      delta: -180,
    );
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsOneWidget,
    );

    pending.completeError(StateError('service unavailable'));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      product,
      find.text('Local market insight could not be loaded'),
    );
    expect(
      find.text('Local market insight could not be loaded'),
      findsOneWidget,
    );
    final retry = find.byKey(
      const ValueKey('buy-wholesale-trade-signal-retry'),
    );
    expect(retry, findsOneWidget);
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
    await reveal(
      tester,
      product,
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      delta: -180,
    );
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale offer blocks Cart and exposes both recovery paths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      productFactsAdapter: _FactsAdapter(
        (product) => factsFor(product, stale: true),
      ),
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('w-onion');

    await tester.pumpWidget(
      app(session, _TradeAdapter((id) async => readySignal(id))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check current availability'), findsWidgets);
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-retry-offer-${product.id}')),
      findsOneWidget,
    );
    final dockRetry = find.byKey(
      ValueKey('buy-wholesale-retry-offer-${product.id}'),
    );
    expect(tester.getSize(dockRetry).height, greaterThanOrEqualTo(48));
    expect(tester.widget<TextButton>(dockRetry).onPressed, isNotNull);
    await reveal(
      tester,
      product,
      find.byKey(ValueKey('buy-offer-retry-${product.id}')),
    );
    expect(
      find.byKey(ValueKey('buy-offer-retry-${product.id}')),
      findsOneWidget,
    );
    final change = find.byKey(
      ValueKey('buy-offer-change-product-${product.id}'),
    );
    expect(change, findsOneWidget);
    expect(session.cartLines, isEmpty);

    await tester.scrollUntilVisible(
      change,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(change);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Android and iOS insets keep the trade action usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewports = <({Size size, double scale, EdgeInsets padding})>[
      for (final scale in [1.0, 2.0])
        (
          size: const Size(360, 800),
          scale: scale,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
      (
        size: const Size(320, 568),
        scale: 1.4,
        padding: const EdgeInsets.only(top: 24, bottom: 24),
      ),
      (
        size: const Size(430, 932),
        scale: 1.2,
        padding: const EdgeInsets.only(top: 47, bottom: 34),
      ),
      for (final scale in [1.0, 2.0])
        (
          size: const Size(640, 360),
          scale: scale,
          padding: const EdgeInsets.only(top: 24, bottom: 34),
        ),
    ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: _FactsAdapter(factsFor),
      );
      final product = session.product('w-onion');
      await tester.pumpWidget(
        app(
          session,
          _TradeAdapter((id) async => readySignal(id)),
          size: viewport.size,
          textScale: viewport.scale,
          padding: viewport.padding,
        ),
      );
      await tester.pumpAndSettle();

      final inline = find.byKey(
        ValueKey('buy-product-inline-action-${product.id}'),
      );
      final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
      final productScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        find.byKey(ValueKey('buy-wholesale-action-dock-${product.id}')),
        findsNothing,
      );
      await tester.scrollUntilVisible(add, 160, scrollable: productScroll);
      await tester.pumpAndSettle();
      expect(add.hitTestable(), findsOneWidget);
      expect(tester.getSize(add).width, 88);
      expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
      expect(find.descendant(of: inline, matching: add), findsOneWidget);
      expect(
        tester.getBottomRight(add).dy,
        lessThanOrEqualTo(viewport.size.height - viewport.padding.bottom),
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), product.minimumOrder);
      final bulkQuantity = (100000000 / product.price).ceil();
      expect(session.setCartQuantity(product.id, '$bulkQuantity'), isTrue);
      await tester.pumpAndSettle();
      final quantity = find.byKey(
        ValueKey('buy-product-quantity-${product.id}'),
      );
      await tester.scrollUntilVisible(quantity, 120, scrollable: productScroll);
      expect(quantity.hitTestable(), findsOneWidget);
      expect(session.cartTotal, product.price * bulkQuantity);
      expect(
        tester.takeException(),
        isNull,
        reason: '${viewport.size}, scale ${viewport.scale}',
      );
      await captureR66Visual(
        tester,
        'r6634-trade-inline-${viewport.size.width}-${viewport.scale}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
      core.dispose();
    }
  });
}

final class _FactsAdapter implements BuyV2ProductFactsAdapter {
  const _FactsAdapter(this.builder);

  final BuyV2ProductFactsSnapshot Function(BuyV2Product product) builder;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      builder(product);
}

final class _TradeAdapter implements BuyV2WholesaleTradeDecisionAdapter {
  const _TradeAdapter(this.builder);

  final Future<BuyV2WholesaleTradeSignal> Function(String productId) builder;

  @override
  Future<BuyV2WholesaleTradeSignal> load({
    required String productId,
    required String canonicalProductId,
    required String? deliveryLocality,
  }) => builder(productId);
}
