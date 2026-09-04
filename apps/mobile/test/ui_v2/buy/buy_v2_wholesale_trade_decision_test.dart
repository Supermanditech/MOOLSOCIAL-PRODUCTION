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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      child: child!,
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
    expect(find.text('WHOLESALE PRICE'), findsOneWidget);
    expect(find.text(buyV2Money(product.price)), findsWidgets);
    expect(find.text('MOQ ${product.minimumOrder} packs'), findsWidgets);
    expect(
      find.text(
        '${buyV2Money(product.price * product.minimumOrder)} minimum total',
      ),
      findsOneWidget,
    );
    expect(find.text('Jodhpur market insight'), findsOneWidget);
    expect(find.text('Steady local restocking'), findsOneWidget);
    expect(
      find.text('MoolSocial local trade activity · Updated 10 minutes ago'),
      findsOneWidget,
    );
    expect(find.text('Current through 6:00 pm today'), findsOneWidget);
    expect(find.textContaining(product.seller), findsWidgets);

    final gallery = find.byKey(ValueKey('buy-product-packshot-${product.id}'));
    expect(tester.getSize(gallery).height, lessThanOrEqualTo(238));
    final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(50));
    final facts = session.productFactsFor(product);
    final deliveryDecision =
        '${buyV2FulfilmentModeLabel(session.fulfilmentModeFor(product))} · '
        '${buyV2BuyerDeliveryPromise(facts)}';
    expect(
      find.byKey(ValueKey('buy-wholesale-dock-delivery-${product.id}')),
      findsOneWidget,
    );
    expect(find.text(deliveryDecision), findsWidgets);
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
    expect(find.text('${product.minimumOrder} packs in Cart'), findsOneWidget);
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
    expect(find.text(product.confirmedOn), findsOneWidget);
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
        matching: find.text('Seller'),
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
    expect(find.text('Checking local market insight'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byKey(ValueKey('buy-product-primary-${product.id}')),
      findsOneWidget,
    );

    pending.completeError(StateError('service unavailable'));
    await tester.pumpAndSettle();
    expect(
      find.text('Local market insight could not be loaded'),
      findsOneWidget,
    );
    final retry = find.byKey(
      const ValueKey('buy-wholesale-trade-signal-retry'),
    );
    expect(retry, findsOneWidget);
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
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
    expect(tester.widget<FilledButton>(dockRetry).onPressed, isNotNull);
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

      final dock = find.byKey(
        ValueKey('buy-wholesale-action-dock-${product.id}'),
      );
      final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
      expect(dock, findsOneWidget, reason: '${viewport.size} dock');
      expect(add, findsOneWidget, reason: '${viewport.size} action');
      expect(
        tester.getSize(add).height,
        greaterThanOrEqualTo(50),
        reason: '${viewport.size} action height',
      );
      expect(
        tester.getBottomRight(dock).dy,
        lessThanOrEqualTo(viewport.size.height - viewport.padding.bottom),
        reason: '${viewport.size} bottom inset',
      );
      expect(tester.takeException(), isNull, reason: '${viewport.size}');

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
