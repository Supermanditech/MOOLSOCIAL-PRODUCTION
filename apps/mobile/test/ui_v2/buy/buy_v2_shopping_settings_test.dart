import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  Future<void> expandTools(WidgetTester tester) async {
    final section = find.byKey(const ValueKey('buy-refine-section-tools'));
    final heading = find
        .descendant(of: section, matching: find.byType(ListTile))
        .first;
    await tester.scrollUntilVisible(
      section,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await Scrollable.ensureVisible(tester.element(heading), alignment: .5);
    await tester.pumpAndSettle();
    expect(heading.hitTestable(), findsOneWidget);
    await tester.tap(heading);
    await tester.pumpAndSettle();
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  for (final collection in ['saved', 'recently-viewed']) {
    testWidgets(
      'R665 O02 $collection product returns through retained settings',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 711);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.openProduct('s-tomato');
        session.closeProduct();
        session.toggleSaved('s-tomato');
        session.addProduct('w-notebook');
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
        await tester.pumpAndSettle();
        await expandTools(tester);
        final settingsAction = find.byKey(
          const ValueKey('buy-shopping-settings-button'),
        );
        await tester.ensureVisible(settingsAction);
        await tester.pumpAndSettle();
        await tester.tap(settingsAction);
        await tester.pumpAndSettle();
        final entry = find.byKey(ValueKey('buy-settings-$collection'));
        await tester.ensureVisible(entry);
        await tester.pumpAndSettle();
        final position = Scrollable.of(tester.element(entry)).position;
        final offset = position.pixels;
        await tester.tap(entry);
        await tester.pumpAndSettle();
        final open = find.byKey(
          ValueKey(
            collection == 'saved'
                ? 'buy-saved-s-tomato'
                : 'buy-settings-recently-viewed-product-s-tomato',
          ),
        );
        await tester.ensureVisible(open);
        await tester.pumpAndSettle();
        await tester.tap(open);
        await tester.pumpAndSettle();
        final label = collection == 'saved'
            ? 'Saved products'
            : 'Recently viewed';
        expect(session.selectedProductId, 's-tomato');
        expect(session.view, BuyV2View.product);
        expect(find.text('Back to $label'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(open.hitTestable(), findsOneWidget);
        expect(session.view, BuyV2View.catalogue);
        await tester.tap(find.byKey(ValueKey('buy-info-sheet-close-$label')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-shopping-settings')),
          findsOneWidget,
        );
        expect(position.pixels, offset);
        expect(session.quantityFor('w-notebook'), 1);
        expect(session.isSaved('s-tomato'), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  void expectCollectionText(WidgetTester tester, Finder owner) {
    final bounds = tester.getRect(owner);
    for (final paragraph in tester.renderObjectList<RenderParagraph>(
      find.descendant(of: owner, matching: find.byType(RichText)),
    )) {
      final label = paragraph.text.toPlainText();
      // Icon fonts have their own single-glyph metrics.
      if (paragraph.text.style?.fontFamily == 'MaterialIcons') continue;
      expect(paragraph.text.style?.fontFamily, 'Inter', reason: label);
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      final natural = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(natural.height - .1),
        reason: label,
      );
      natural.dispose();
      final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
      expect(rect.left, greaterThanOrEqualTo(bounds.left - .1), reason: label);
      expect(rect.right, lessThanOrEqualTo(bounds.right + .1), reason: label);
      expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + .1), reason: label);
      for (final word in label.split(RegExp(r'\s+'))) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: paragraph.text.style),
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout();
        expect(
          painter.width,
          lessThanOrEqualTo(paragraph.size.width + .1),
          reason: 'Whole word must fit: $word in $label',
        );
        painter.dispose();
      }
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final viewport in [
      const Size(320, 700),
      const Size(360, 800),
      const Size(430, 900),
      const Size(640, 360),
    ]) {
      for (final scale in [1.0, 1.4, 2.0]) {
        for (final collection in ['saved', 'recently-viewed']) {
          testWidgets(
            'R5 029H collection facts and actions ${destination.name} '
            '$collection ${viewport.width.toInt()}x${viewport.height.toInt()} $scale',
            (tester) async {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = viewport;
              tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
              tester.view.viewPadding = const FakeViewPadding(
                top: 24,
                bottom: 24,
              );
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(tester.view.reset);
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              final core = BuySession();
              final session = BuyV2Session(core: core);
              addTearDown(core.dispose);
              addTearDown(session.dispose);
              final productId = destination == BuyV2Destination.shop
                  ? 's-milk'
                  : 'w-rice-50kg';
              final otherId = destination == BuyV2Destination.shop
                  ? 'w-rice'
                  : 's-tomato';
              session.addProduct(otherId);
              final otherQuantity = session.quantityFor(otherId);
              if (collection == 'recently-viewed') {
                session.openProduct(otherId);
                session.closeProduct();
              }
              session.openDestination(destination);
              session.openProduct(productId);
              session.closeProduct();
              session.toggleSaved(productId);
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: MoolTheme.light(),
                  builder: (_, child) => r66VisualCaptureRoot(child!),
                  home: Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        onPressed: () =>
                            showBuyV2ShoppingSettings(context, session),
                        child: const Text('Open settings'),
                      ),
                    ),
                  ),
                ),
              );
              await tester.tap(find.text('Open settings'));
              await tester.pumpAndSettle();
              final entry = find.byKey(ValueKey('buy-settings-$collection'));
              await tester.ensureVisible(entry);
              await tester.pumpAndSettle();
              if (collection == 'recently-viewed') {
                expect(
                  find.descendant(
                    of: entry,
                    matching: find.text(
                      '${destination.label} · 1 recently viewed',
                    ),
                  ),
                  findsOneWidget,
                );
                expectCollectionText(tester, entry);
                await captureR66Visual(
                  tester,
                  'r669-recent-scope-${destination.name}-'
                  '${viewport.width.toInt()}x${viewport.height.toInt()}-$scale',
                );
              }
              final position = Scrollable.of(tester.element(entry)).position;
              final originalOffset = position.pixels;
              await tester.tap(entry);
              await tester.pumpAndSettle();
              if (collection == 'recently-viewed') {
                expect(
                  find.text('${destination.label} · 1 product'),
                  findsOneWidget,
                );
                expect(
                  find.byKey(
                    ValueKey('buy-settings-recently-viewed-product-$otherId'),
                  ),
                  findsNothing,
                );
              }
              final product = session.product(productId);
              final open = find.byKey(
                ValueKey(
                  collection == 'saved'
                      ? 'buy-saved-$productId'
                      : 'buy-settings-recently-viewed-product-$productId',
                ),
              );
              await tester.ensureVisible(open);
              await tester.pumpAndSettle();
              expectCollectionText(tester, open);
              expect(
                find.descendant(of: open, matching: find.text(product.title)),
                findsOneWidget,
              );
              final price = collection == 'saved'
                  ? product.price
                  : session.productFactsFor(product).price;
              expect(
                find.descendant(
                  of: open,
                  matching: find.text('${product.pack} · ${buyV2Money(price)}'),
                ),
                findsOneWidget,
              );
              if (collection == 'recently-viewed') {
                expect(
                  find.descendant(
                    of: open,
                    matching: find.text(
                      buyV2BuyerDeliveryPromise(
                        session.productFactsFor(product),
                      ),
                    ),
                  ),
                  findsOneWidget,
                );
              }
              final captureName =
                  'r5-029h-${destination.name}-$collection-'
                  '${viewport.width.toInt()}x${viewport.height.toInt()}-$scale';
              final labels = find.descendant(
                of: open,
                matching: find.byType(Text),
              );
              await tester.ensureVisible(labels.first);
              await tester.pumpAndSettle();
              await captureR66Visual(tester, '$captureName-facts');
              final list = find
                  .ancestor(of: open, matching: find.byType(ListView))
                  .first;
              final initialScroll = Scrollable.of(
                tester.element(open),
              ).position.pixels;
              for (final element in labels.evaluate().toList()) {
                final label = find.byWidget(element.widget);
                await tester.ensureVisible(label);
                await tester.pumpAndSettle();
                final labelBounds = tester.getRect(label);
                final viewportBounds = tester.getRect(list);
                expect(
                  labelBounds.top,
                  greaterThanOrEqualTo(viewportBounds.top - .1),
                );
                expect(
                  labelBounds.bottom,
                  lessThanOrEqualTo(viewportBounds.bottom + .1),
                );
              }
              if (Scrollable.of(tester.element(open)).position.pixels !=
                  initialScroll) {
                await captureR66Visual(tester, '$captureName-facts-scrolled');
              }
              if (collection == 'recently-viewed') {
                final add = find.byKey(
                  ValueKey('buy-recently-viewed-add-$productId'),
                );
                await tester.ensureVisible(add);
                await tester.pumpAndSettle();
                expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
                expect(tester.getSize(add).width, greaterThanOrEqualTo(44));
                expectCollectionText(tester, add);
                final label = tester.renderObject<RenderParagraph>(
                  find.descendant(of: add, matching: find.text('Add')),
                );
                expect(label.text.style?.fontFamily, 'Inter');
                await tester.tap(add);
                await tester.pumpAndSettle();
                expect(session.quantityFor(productId), 1);
                expect(session.quantityFor(otherId), otherQuantity);
                expectCollectionText(tester, add);
                expect(
                  find.descendant(of: add, matching: find.text('Added')),
                  findsOneWidget,
                );
                await captureR66Visual(tester, '$captureName-added');
              } else {
                final remove = find.byKey(ValueKey('buy-unsave-$productId'));
                await tester.ensureVisible(remove);
                await tester.pumpAndSettle();
                expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
                expect(tester.getSize(remove).width, greaterThanOrEqualTo(44));
                await tester.tap(remove);
                await tester.pumpAndSettle();
                expect(session.savedProductsFor(destination), isEmpty);
                expect(find.text('No saved products yet'), findsOneWidget);
              }
              final close = find.byKey(
                ValueKey(
                  'buy-info-sheet-close-'
                  '${collection == 'saved' ? 'Saved products' : 'Recently viewed'}',
                ),
              );
              expect(tester.getSize(close).height, greaterThanOrEqualTo(44));
              await tester.tap(close);
              await tester.pumpAndSettle();
              expect(position.pixels, originalOffset);
              if (collection == 'saved') session.toggleSaved(productId);
              if (collection == 'recently-viewed') {
                session.clearRecentlyViewed(destination);
                await tester.pumpAndSettle();
                expect(
                  session
                      .recentlyViewedProductsFor(
                        session.product(otherId).destination,
                      )
                      .map((product) => product.id),
                  contains(otherId),
                );
                await tester.ensureVisible(entry);
                await tester.pumpAndSettle();
                expect(
                  find.descendant(
                    of: entry,
                    matching: find.text(
                      '${destination.label} · No recently viewed products',
                    ),
                  ),
                  findsOneWidget,
                );
                expectCollectionText(tester, entry);
                await tester.tap(entry);
                await tester.pumpAndSettle();
                expect(
                  find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
                  findsNothing,
                );
                session.openProduct(productId);
                session.closeProduct();
                await tester.pumpAndSettle();
                await tester.ensureVisible(entry);
                await tester.pumpAndSettle();
              }
              await tester.tap(entry);
              await tester.pumpAndSettle();
              await tester.ensureVisible(open);
              await tester.pumpAndSettle();
              expect(tester.getSize(open).height, greaterThanOrEqualTo(44));
              await tester.tap(open);
              await tester.pumpAndSettle();
              expect(session.selectedProductId, productId);
              expect(session.view, BuyV2View.product);
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsNothing,
              );
              expect(session.quantityFor(otherId), otherQuantity);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  for (final scenario in [
    for (final destination in [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
    ])
      for (final viewport in [const Size(320, 700), const Size(640, 360)])
        for (final scale in [1.0, 2.0]) (destination, viewport, scale),
  ]) {
    final (destination, viewport, scale) = scenario;
    for (final populated in [false, true]) {
      testWidgets(
        'R5 033 settings collections retain origin after entry unmounts '
        '${destination.name} populated=$populated $viewport $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          final entryVisible = ValueNotifier(true);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          addTearDown(entryVisible.dispose);
          final productId = destination == BuyV2Destination.shop
              ? 's-milk'
              : 'w-rice';
          session.openDestination(destination);
          expect(session.openProduct(productId), isTrue);
          session.closeProduct();
          if (populated) session.toggleSaved(productId);
          session.addProduct('s-tomato');
          final cartQuantity = session.itemCount;
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              builder: (_, child) => r66VisualCaptureRoot(child!),
              home: Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: entryVisible,
                  builder: (_, visible, _) => visible
                      ? Builder(
                          builder: (context) => TextButton(
                            onPressed: () =>
                                showBuyV2ShoppingSettings(context, session),
                            child: const Text('Open settings'),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open settings'));
          await tester.pumpAndSettle();
          // A nested route can rebuild the catalogue that opened Settings.
          // The still-visible sheet must not depend on that old entry context.
          entryVisible.value = false;
          await tester.pumpAndSettle();
          final settings = find.byKey(const ValueKey('buy-shopping-settings'));
          for (final collection in ['saved', 'recently-viewed']) {
            final row = find.byKey(ValueKey('buy-settings-$collection'));
            await tester.ensureVisible(row);
            await tester.pumpAndSettle();
            final position = Scrollable.of(tester.element(row)).position;
            final offset = position.pixels;
            final rowTop = tester.getTopLeft(row).dy;
            for (var visit = 0; visit < 2; visit++) {
              await tester.tap(row);
              await tester.pumpAndSettle();
              expect(
                find.byKey(
                  ValueKey(
                    collection == 'saved'
                        ? 'buy-saved-products-info-sheet'
                        : 'buy-recently-viewed-info-sheet',
                  ),
                ),
                findsOneWidget,
              );
              expect(tester.takeException(), isNull);
              if (visit == 0) {
                await captureR66Visual(
                  tester,
                  'r5-collection-${destination.name}-$populated-$collection-'
                  '${viewport.width.toInt()}x${viewport.height.toInt()}-$scale',
                );
              }
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(settings, findsOneWidget);
              expect(position.pixels, offset);
              expect(tester.getTopLeft(row).dy, rowTop);
              expect(session.destination, destination);
              expect(session.itemCount, cartQuantity);
              expect(tester.takeException(), isNull);
            }
          }
        },
      );
    }
  }

  for (final viewport in [const Size(320, 700), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R5 029G complete settings descriptions $viewport $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (_, child) => r66VisualCaptureRoot(child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showBuyV2ShoppingSettings(context, session),
                  child: const Text('Open settings'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open settings'));
        await tester.pumpAndSettle();
        for (final name in ['privacy', 'security', 'help']) {
          final row = find.byKey(ValueKey('buy-settings-$name'));
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(row);
          expect(bounds.height, greaterThanOrEqualTo(44));
          for (final paragraph in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: row, matching: find.byType(RichText)),
          )) {
            expect(paragraph.didExceedMaxLines, isFalse);
            final textBounds =
                paragraph.localToGlobal(Offset.zero) & paragraph.size;
            expect(textBounds.left, greaterThanOrEqualTo(bounds.left));
            expect(textBounds.right, lessThanOrEqualTo(bounds.right));
            expect(textBounds.top, greaterThanOrEqualTo(bounds.top));
            expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
          }
          await captureR66Visual(
            tester,
            'r5-settings-$name-${viewport.width.toInt()}x${viewport.height.toInt()}-$scale',
          );
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R5 020 delivery choices stay in the catalogue at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.viewPadding = const FakeViewPadding(bottom: 32);
      tester.view.padding = const FakeViewPadding(bottom: 32);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.addProduct('s-milk');
      final quantity = session.quantityFor('s-milk');

      Future<void> openSettings(BuyV2Session current) async {
        await tester.pumpWidget(
          MaterialApp(
            key: ObjectKey(current),
            theme: MoolTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showBuyV2ShoppingSettings(context, current),
                  child: const Text('Open settings'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open settings'));
        await tester.pumpAndSettle();
      }

      for (final mode in BuyV2ShopSaleType.values) {
        session.chooseShopSaleType(mode);
        await openSettings(session);
        expect(
          find.byKey(const ValueKey('buy-settings-delivery')),
          findsNothing,
        );
        expect(find.textContaining('Preferred delivery'), findsNothing);
        expect(
          find.byKey(const ValueKey('buy-settings-addresses')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-settings-payment')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.shopSaleType, mode);
        expect(session.selectedFulfilmentMode, isNull);
        expect(session.quantityFor('s-milk'), quantity);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('shopping settings reuse owners and fit at 320 large text', (
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
    session.closeProduct();
    session.toggleSaved('s-milk');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    await expandTools(tester);
    final openSettings = find.byKey(
      const ValueKey('buy-shopping-settings-button'),
    );
    await tester.scrollUntilVisible(
      openSettings,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(tester.element(openSettings), alignment: .5);
    await tester.pumpAndSettle();
    expect(openSettings.hitTestable(), findsOneWidget);
    await tester.tap(openSettings);
    await tester.pumpAndSettle();

    final settings = find.byKey(const ValueKey('buy-shopping-settings'));
    final settingsScroll = find
        .descendant(of: settings, matching: find.byType(Scrollable))
        .first;
    expect(settings, findsOneWidget);
    expect(find.text('Shopping settings'), findsOneWidget);
    for (final keyName in const [
      'buy-settings-addresses',
      'buy-settings-payment',
      'buy-settings-order-alerts',
      'buy-settings-saved',
      'buy-settings-recently-viewed',
      'buy-settings-messages',
      'buy-settings-privacy',
      'buy-settings-security',
      'buy-settings-help',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(keyName)),
        160,
        scrollable: settingsScroll,
      );
      expect(find.byKey(ValueKey(keyName)), findsOneWidget);
    }

    expect(find.byKey(const ValueKey('buy-settings-delivery')), findsNothing);
    expect(session.selectedFulfilmentMode, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-settings-order-alerts')),
      160,
      scrollable: settingsScroll,
    );
    expect(session.trackingAlertsEnabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('buy-settings-order-alerts')));
    await tester.pumpAndSettle();
    expect(session.trackingAlertsEnabled, isFalse);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-settings-recently-viewed')),
      160,
      scrollable: settingsScroll,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-settings-recently-viewed')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
      findsOneWidget,
    );
    expect(find.text('Clear recently viewed?'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('buy-recently-viewed-sheet-clear')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Clear recently viewed?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('buy-settings-recently-viewed-confirm')),
    );
    await tester.pumpAndSettle();
    expect(session.recentlyViewedProductsFor(session.destination), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tools exposes Recently viewed without hiding it in settings', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);
    session.closeProduct();

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    await expandTools(tester);

    final recentlyViewed = find.byKey(
      const ValueKey('buy-recently-viewed-button'),
    );
    await tester.scrollUntilVisible(
      recentlyViewed,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(recentlyViewed),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    expect(recentlyViewed.hitTestable(), findsOneWidget);
    await tester.tap(recentlyViewed);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
      findsOneWidget,
    );
    final add = find.byKey(const ValueKey('buy-recently-viewed-add-s-milk'));
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-milk'), 1);
    expect(find.text('Added'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-settings-recently-viewed')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shopping settings reopens an exact recently viewed product and returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);
      session.closeProduct();

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      await expandTools(tester);
      final openSettings = find.byKey(
        const ValueKey('buy-shopping-settings-button'),
      );
      await tester.scrollUntilVisible(
        openSettings,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await Scrollable.ensureVisible(
        tester.element(openSettings),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(openSettings.hitTestable(), findsOneWidget);
      await tester.tap(openSettings);
      await tester.pumpAndSettle();

      final settings = find.byKey(const ValueKey('buy-shopping-settings'));
      final settingsScroll = find
          .descendant(of: settings, matching: find.byType(Scrollable))
          .first;
      final recentlyViewed = find.byKey(
        const ValueKey('buy-settings-recently-viewed'),
      );
      await tester.scrollUntilVisible(
        recentlyViewed,
        160,
        scrollable: settingsScroll,
      );
      await tester.tap(recentlyViewed);
      await tester.pumpAndSettle();

      expect(settings, findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('buy-settings-recently-viewed-product-s-milk'),
        ),
      );
      await tester.pumpAndSettle();

      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 's-milk');
      expect(settings, findsNothing);
      expect(
        find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
        findsNothing,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, BuyV2Destination.shop);
      expect(tester.takeException(), isNull);
    },
  );
}
