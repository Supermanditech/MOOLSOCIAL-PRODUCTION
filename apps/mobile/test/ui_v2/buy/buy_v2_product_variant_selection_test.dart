import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

Future<void> capturePack(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    repaint(boundary);
    await captureR66Visual(tester, label);
  } finally {
    debugDisableShadows = previousShadows;
    repaint(boundary);
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final offers in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R5 singular trade pack from offers $offers at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.addProduct('s-milk');
        final otherQuantity = session.quantityFor('s-milk');
        final otherTotal = session.totalForDestination(BuyV2Destination.shop);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                disableAnimations: true,
              ),
              child: r66VisualCaptureRoot(child!),
            ),
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            ValueKey(
              offers ? 'buy-local-tab-offers' : 'buy-local-tab-wholesale',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sourceId = offers ? 'w-oil' : 'w-rice';
        final selectedId = offers ? 'w-oil-10l' : 'w-rice-50kg';
        if (!offers) {
          await tester.tap(find.byKey(const ValueKey('buy-search-control')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            'rice',
          );
          await tester.pumpAndSettle();
        }
        final source = session.product(sourceId);
        final sourceCard = find.byKey(ValueKey('buy-product-$sourceId'));
        await Scrollable.ensureVisible(
          tester.element(sourceCard),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(sourceCard.hitTestable(), findsOneWidget);
        await tester.tap(sourceCard);
        await tester.pumpAndSettle();
        final selector = find.byKey(
          ValueKey('buy-product-variants-${source.canonicalId}'),
        );
        await tester.scrollUntilVisible(
          selector,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$sourceId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final variant = find.byKey(ValueKey('buy-product-variant-$selectedId'));
        await tester.ensureVisible(variant);
        await tester.pumpAndSettle();
        await tester.tap(variant);
        await tester.pumpAndSettle();
        final selected = session.selectedProduct!;
        expect(selected.id, selectedId);
        expect(selected.minimumOrder, 1);
        expect(selected.price, offers ? 1580 : 3200);
        expect(selected.seller, source.seller);
        expect(session.quantityFor(sourceId), 0);
        final label = find.text('Minimum 1 pack · ${selected.pack} each');
        expect(label, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
        );
        final addLabel = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label ?? '').startsWith(
                'Add minimum order of 1 pack of ',
              ),
        );
        expect(addLabel, findsOneWidget);
        expect(find.textContaining(RegExp(r'\b1 packs\b')), findsNothing);
        await capturePack(tester, 'r5-pack-$offers-$scale-minimum');
        final trade = find.text('MOQ 1 pack');
        await tester.scrollUntilVisible(
          trade,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final priceSummary = find.byKey(
          ValueKey('buy-wholesale-price-summary-$selectedId'),
        );
        expect(
          find.descendant(
            of: priceSummary,
            matching: find.text('${selected.pack} · ${selected.unitPrice}'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: priceSummary, matching: trade),
          findsOneWidget,
        );
        final tradeSemantics = find.byKey(
          ValueKey('buy-wholesale-trade-decision-$selectedId'),
        );
        await tester.scrollUntilVisible(
          tradeSemantics,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(tradeSemantics).properties.label,
          contains('Minimum order 1 pack.'),
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-trade');
        final add = find.byKey(ValueKey('buy-product-primary-$selectedId'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(selectedId), 1);
        expect(
          session.totalForDestination(BuyV2Destination.wholesale),
          selected.price,
        );
        expect(find.text('1 pack in Cart'), findsOneWidget);
        await capturePack(tester, 'r5-pack-$offers-$scale-one-in-cart');
        final stepper = find.byKey(
          ValueKey('buy-product-quantity-$selectedId'),
        );
        await tester.tap(
          find.descendant(of: stepper, matching: find.byTooltip('Add one')),
        );
        await tester.pumpAndSettle();
        expect(session.quantityFor(selectedId), 2);
        expect(find.text('2 packs in Cart'), findsOneWidget);
        expect(
          session.totalForDestination(BuyV2Destination.wholesale),
          selected.price * 2,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-two-in-cart');
        await tester.tap(
          find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').contains(
                  'Minimum order 1 packs.',
                ),
          ),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').contains(
                  'Minimum order 1 pack.',
                ),
          ),
          findsWidgets,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-cart');
        final cartFacts = find.byKey(
          ValueKey('buy-wholesale-cart-line-facts-$selectedId'),
        );
        await Scrollable.ensureVisible(
          tester.element(cartFacts),
          alignment: .45,
        );
        await tester.pumpAndSettle();
        final cartPackLabel = find.descendant(
          of: cartFacts,
          matching: find.textContaining('MOQ 1 pack'),
        );
        expect(cartPackLabel.hitTestable(), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(cartPackLabel).didExceedMaxLines,
          isFalse,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-cart-moq');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, selectedId);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        if (offers) {
          final collection = find.byKey(const PageStorageKey('buy-offers'));
          expect(collection, findsOneWidget);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('buy-offers-publisher-summary')),
            -200,
            scrollable: find
                .descendant(of: collection, matching: find.byType(Scrollable))
                .first,
          );
        }
        expect(
          find.byKey(const ValueKey('buy-offers-publisher-summary')),
          offers ? findsOneWidget : findsNothing,
        );
        expect(session.quantityFor('s-milk'), otherQuantity);
        expect(session.totalForDestination(BuyV2Destination.shop), otherTotal);
        expect(session.quantityFor(selectedId), 2);
        await capturePack(tester, 'r5-pack-$offers-$scale-return');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('product options preserve exact pack Cart and Back state', (
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
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          productId: session.selectedProductId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = find.byKey(const ValueKey('buy-product-variants-milk'));
    await tester.scrollUntilVisible(
      selector,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(selector, findsOneWidget);
    for (final id in const ['s-milk', 's-milk-500ml', 's-milk-2l']) {
      expect(find.byKey(ValueKey('buy-product-variant-$id')), findsOneWidget);
    }

    final halfLitre = find.byKey(
      const ValueKey('buy-product-variant-s-milk-500ml'),
    );
    await tester.ensureVisible(halfLitre);
    await tester.pumpAndSettle();
    await tester.tap(halfLitre);
    await tester.pumpAndSettle();
    expect(session.selectedProduct?.id, 's-milk-500ml');
    expect(find.text('500 ml pouch'), findsWidgets);

    final add = find.byKey(const ValueKey('buy-product-primary-s-milk-500ml'));
    await tester.scrollUntilVisible(
      add,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk-500ml')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-product-hero-delivery-s-milk-500ml')),
      findsOneWidget,
    );
    expect(find.textContaining('Standard/courier delivery'), findsWidgets);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-milk-500ml'), 1);
    expect(session.quantityFor('s-milk'), 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view.name, 'catalogue');
    expect(tester.takeException(), isNull);
  });
}
