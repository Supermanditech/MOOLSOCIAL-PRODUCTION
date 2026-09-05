import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) =>
        const bool.fromEnvironment('BUY_R66_RECENT_CAPTURE')
        ? RepaintBoundary(
            key: const ValueKey('r66-recent-review-capture'),
            child: child!,
          )
        : child!,
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      productId: session.selectedProductId,
    ),
  );

  for (final productId in ['s-tomato', 'w-notebook']) {
    for (final width in [320.0, 430.0]) {
      testWidgets(
        'R66 Recently Viewed fits $productId at $width and 200 percent',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          final product = session.product(productId);
          session.openDestination(product.destination);
          expect(session.openProduct(productId), isTrue);
          session.closeProduct();
          await tester.pumpWidget(app(session));
          await tester.pumpAndSettle();
          final rail = find.byKey(const ValueKey('buy-recently-viewed'));
          await tester.scrollUntilVisible(
            rail,
            220,
            scrollable: find
                .descendant(
                  of: find.byType(BuyV2CatalogueView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          final card = find.byKey(
            ValueKey('buy-recently-viewed-product-$productId'),
          );
          final labels = find.descendant(of: card, matching: find.byType(Text));
          for (final element in labels.evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            final natural = TextPainter(
              text: paragraph.text,
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
              maxLines: paragraph.maxLines,
            )..layout(maxWidth: paragraph.size.width);
            expect(paragraph.size.height, greaterThanOrEqualTo(natural.height));
            natural.dispose();
            expect(
              tester.getRect(find.byWidget(element.widget)).bottom,
              lessThanOrEqualTo(tester.getRect(card).bottom),
            );
          }
          expect(tester.getSize(card).height, greaterThanOrEqualTo(44));
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('BUY_R66_RECENT_CAPTURE')) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('r66-recent-review-capture')),
            );
            await tester.runAsync(() async {
              final directory = Directory(
                'build/r66-recent-review-v1-20260905',
              );
              await directory.create(recursive: true);
              final output = File(
                '${directory.path}/$productId-$width-text2.png',
              );
              if (await output.exists()) {
                throw StateError('Capture already exists');
              }
              final image = await boundary.toImage(pixelRatio: 2);
              try {
                final bytes = await image.toByteData(
                  format: ImageByteFormat.png,
                );
                if (bytes == null) throw StateError('Capture encoding failed');
                await output.writeAsBytes(bytes.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }
          await tester.tap(card);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, productId);
        },
      );
    }
  }

  test(
    'recently viewed keeps exact products, restores and stays bounded',
    () async {
      final store = _MemoryCustomerStateStore();
      final core = BuySession();
      final session = BuyV2Session(core: core, customerStateStore: store);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      final products = BuyV2Catalogue.products
          .where(
            (product) =>
                product.destination == BuyV2Destination.shop ||
                product.destination == BuyV2Destination.wholesale,
          )
          .toList(growable: false);
      expect(products.length, greaterThan(10));
      for (final product in products) {
        expect(session.openProduct(product.id), isTrue);
      }
      final retained = [
        ...session.recentlyViewedProductsFor(BuyV2Destination.shop),
        ...session.recentlyViewedProductsFor(BuyV2Destination.wholesale),
      ];
      expect(retained, hasLength(10));
      expect(retained.map((product) => product.id), contains(products.last.id));
      expect(store.snapshot?.recentlyViewedProductIds, hasLength(10));

      final restoredCore = BuySession();
      final restored = BuyV2Session(
        core: restoredCore,
        customerStateStore: store,
      );
      addTearDown(restored.dispose);
      addTearDown(restoredCore.dispose);
      await restored.restoreCustomerState();
      expect(
        restored.recentlyViewedProductsFor(BuyV2Destination.medicine),
        isEmpty,
      );
      expect([
        ...restored.recentlyViewedProductsFor(BuyV2Destination.shop),
        ...restored.recentlyViewedProductsFor(BuyV2Destination.wholesale),
      ], hasLength(10));

      restored.clearRecentlyViewed(BuyV2Destination.shop);
      expect(
        restored.recentlyViewedProductsFor(BuyV2Destination.shop),
        isEmpty,
      );
      expect(
        restored.recentlyViewedProductsFor(BuyV2Destination.wholesale),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'recently viewed reopens exact variant and clears at large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);
      expect(session.selectProductVariant('s-milk-2l'), isTrue);
      session.closeProduct();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final rail = find.byKey(const ValueKey('buy-recently-viewed'));
      await tester.scrollUntilVisible(
        rail,
        240,
        scrollable: find
            .descendant(
              of: find.byType(BuyV2CatalogueView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Recently viewed'), findsOneWidget);
      expect(find.text('2 × 1 L pouches'), findsWidgets);

      final exactVariant = find.byKey(
        const ValueKey('buy-recently-viewed-product-s-milk-2l'),
      );
      await tester.tap(exactVariant);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-milk-2l');
      expect(session.view, BuyV2View.product);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      await tester.scrollUntilVisible(
        rail,
        240,
        scrollable: find
            .descendant(
              of: find.byType(BuyV2CatalogueView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('buy-recently-viewed-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-recently-viewed')), findsNothing);
      expect(session.view, BuyV2View.catalogue);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _MemoryCustomerStateStore implements BuyV2CustomerStateStore {
  BuyV2CustomerStateSnapshot? snapshot;

  @override
  String? get ownerScope => 'customer:recently-viewed';

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}
