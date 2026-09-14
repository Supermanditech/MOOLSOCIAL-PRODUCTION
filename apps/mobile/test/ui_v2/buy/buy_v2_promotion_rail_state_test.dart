import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 fresh promotion starts at product top $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core, reviewDataEnabled: true);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: r66VisualCaptureRoot(child!),
          ),
          home: BuyV2Screen(session: session, initialOffersActive: true),
        ),
      );
      await tester.pumpAndSettle();
      final cta = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'buy-offer-promotion-cta-',
            ),
      );
      Future<void> openOffer() async {
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
      }

      await openOffer();
      final productId = session.selectedProductId!;
      ScrollableState productScroll() => tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-$productId')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      productScroll().position.jumpTo(650);
      await tester.pumpAndSettle();
      final retainedOffset = productScroll().position.pixels;
      expect(retainedOffset, greaterThan(0));
      expect(session.addProduct(productId), isTrue);
      final quantity = session.quantityFor(productId);
      session.openCart();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(productScroll().position.pixels, closeTo(retainedOffset, 1));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await openOffer();
      expect(session.selectedProductId, productId);
      expect(
        productScroll().position.pixels,
        0,
        reason:
            'A fresh promotion tap must not reuse a previous review position',
      );
      expect(session.quantityFor(productId), quantity);
      expect(tester.takeException(), isNull);
      await captureR66Visual(tester, 'r669-fresh-offer-entry-$scale');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  test(
    'delivery label is not duplicated when the source is already labelled',
    () {
      expect(
        buyV2BuyerDeliveryPromiseSource(
          'Delivery schedule confirmed at checkout',
        ),
        'Delivery schedule confirmed at checkout',
      );
      expect(
        buyV2BuyerDeliveryPromiseSource(
          'Supplier delivery schedule awaiting confirmation',
        ),
        'Supplier delivery schedule awaiting confirmation',
      );
    },
  );

  testWidgets('both promotion intents fit without horizontal clipping', (
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
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    void expectContained(List<ValueKey<String>> keys) {
      final owner = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
      );
      for (final key in keys) {
        final rect = tester.getRect(find.byKey(key));
        expect(owner.contains(rect.topLeft), isTrue);
        expect(owner.contains(rect.bottomRight), isTrue);
        expect(rect.width, greaterThanOrEqualTo(140));
        expect(rect.height, greaterThanOrEqualTo(44));
        final copy = find.descendant(
          of: find.byKey(key),
          matching: find.byType(RichText),
        );
        for (final text in copy.evaluate()) {
          final paragraph = text.renderObject! as RenderParagraph;
          expect(paragraph.didExceedMaxLines, isFalse);
          final textBounds = tester.getRect(find.byWidget(text.widget));
          expect(textBounds.left, greaterThanOrEqualTo(rect.left));
          expect(textBounds.right, lessThanOrEqualTo(rect.right));
        }
      }
    }

    expectContained(const [
      ValueKey('buy-promotion-shop-basket'),
      ValueKey('buy-promotion-shop-wholesale'),
    ]);
    final monthlyBasketTitle = tester.widget<Text>(
      find.text('Plan the monthly basket'),
    );
    expect(monthlyBasketTitle.maxLines, 3);
    expect(monthlyBasketTitle.overflow, TextOverflow.clip);

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expectContained(const [
      ValueKey('buy-promotion-wholesale-restock'),
      ValueKey('buy-promotion-wholesale-shop'),
    ]);
    for (final copy in const [
      'Compare products with lower minimum packs',
      'Browse retail packs sized for home',
    ]) {
      final text = tester.widget<Text>(find.text(copy));
      expect(text.maxLines, 4);
    }
    expect(tester.takeException(), isNull);
  });
}
