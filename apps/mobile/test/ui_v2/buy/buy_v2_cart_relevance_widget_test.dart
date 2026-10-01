import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'buy_v2_qualified_provider_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session, {double textScale = 1}) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: _r66CartCaptureBoundary(child!),
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
      ),
    );
  }

  Future<void> showInMainCartList(
    WidgetTester tester,
    Finder target, {
    double scrollDelta = 450,
  }) async {
    final scrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    if (target.evaluate().isEmpty && scrollDelta > 0) {
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
    }
    final step =
        scrollDelta.sign *
        scrollDelta.abs().clamp(1.0, tester.getSize(scrollable).height * .6);
    await tester.scrollUntilVisible(
      target,
      step,
      scrollable: scrollable,
      maxScrolls: 80,
    );
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('T01 mixed Cart filters and deselection remain usable at $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      session.addProduct('w-notebook');
      session.openCart();
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      final selectedFilter = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('buy-cart-filter-all')),
      );
      expect(
        selectedFilter.labelStyle?.color,
        BuyV2ActionStyle.primaryForeground,
      );
      expect(
        selectedFilter.labelStyle?.color,
        isNot(selectedFilter.selectedColor),
      );
      final cardRect = tester.getRect(
        find.byKey(const ValueKey('buy-cart-line-s-tomato')),
      );
      final selectionRect = tester.getRect(
        find.byKey(const ValueKey('buy-cart-select-s-tomato')),
      );
      expect(
        cardRect.contains(selectionRect.center),
        isTrue,
        reason: 'Selection shares card width instead of a separate gutter',
      );
      expect(cardRect.width, greaterThan(320));
      final total = session.scopedPayableTotal;
      await tester.tap(find.byKey(const ValueKey('buy-cart-filter-shop')));
      await tester.pumpAndSettle();
      expect(session.visibleCartLines.single.product.id, 's-tomato');
      expect(session.scopedPayableTotal, total);
      await tester.tap(find.byKey(const ValueKey('buy-cart-select-s-tomato')));
      await tester.pumpAndSettle();
      expect(session.cartLines.single.product.id, 'w-notebook');
      expect(
        find.byKey(const ValueKey('buy-cart-select-s-tomato')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-cart-select-s-tomato')));
      await tester.pumpAndSettle();
      expect(session.scopedPayableTotal, total);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      for (var mask = 1; mask < 8; mask++) {
        final combinationCore = BuySession();
        final combination = BuyV2Session(core: combinationCore);
        const ids = ['s-tomato', 'w-notebook', 'w-rice'];
        for (var i = 0; i < ids.length; i++) {
          if ((mask & (1 << i)) != 0) {
            expect(combination.addProduct(ids[i]), isTrue);
          }
        }
        combination.openCart();
        await tester.pumpWidget(app(combination, textScale: scale));
        await tester.pumpAndSettle();
        final payable = combination.scopedPayableTotal;
        final initialType = mask == 1
            ? 'shop'
            : mask == 2
            ? 'wholesale'
            : mask == 4
            ? 'bulk'
            : 'all';
        final discoveryType = find.byKey(
          ValueKey('buy-cart-discovery-type-$initialType'),
        );
        await showInMainCartList(tester, discoveryType);
        expect(tester.widget<ChoiceChip>(discoveryType).selected, isTrue);
        final quantitiesBefore = {
          for (final line in combination.cartLines)
            line.product.id: line.quantity,
        };
        for (final type in ['shop', 'wholesale', 'bulk', 'all']) {
          final choice = find.byKey(ValueKey('buy-cart-discovery-type-$type'));
          await showInMainCartList(tester, choice);
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(tester.widget<ChoiceChip>(choice).selected, isTrue);
          expect(combination.cartDisplayFilter, 'all');
          expect(combination.scopedPayableTotal, payable);
          expect({
            for (final line in combination.cartLines)
              line.product.id: line.quantity,
          }, quantitiesBefore);
          final expected = [
            ...combination.cartRecommendationsFor(
              BuyV2Destination.shop,
              purchaseType: type,
              limit: 1000,
            ),
            ...combination.cartRecommendationsFor(
              BuyV2Destination.wholesale,
              purchaseType: type,
              limit: 1000,
            ),
          ];
          final discovery = find.byKey(
            const PageStorageKey('buy-cart-discovery'),
          );
          final cards = find.descendant(
            of: discovery,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is InkWell &&
                  w.key.toString().contains('buy-cart-recommendation-'),
            ),
          );
          expect(cards.evaluate().length, lessThanOrEqualTo(24));
          final basketProducts = combination.cartLines
              .map((line) => line.product)
              .toList();
          final storeFirst = [
            ...expected.where((p) => basketProducts.any(p.isFromSameStoreAs)),
            ...expected.where((p) => !basketProducts.any(p.isFromSameStoreAs)),
          ].take(24).toList();
          final categoryRows = <String, List<BuyV2Product>>{};
          for (final product in storeFirst) {
            final id = '${product.destination.name}:${product.categoryId}';
            categoryRows.putIfAbsent(id, () => []).add(product);
          }
          expect(
            cards.evaluate().map((e) => e.widget.key),
            categoryRows.values
                .take(4)
                .expand((row) => row)
                .map((p) => ValueKey('buy-cart-recommendation-${p.id}')),
            reason:
                'Distinct category rows retain each exact SKU once and basket Stores first within each category',
          );
          for (final row in categoryRows.entries.take(4)) {
            final shelf = find.byKey(
              ValueKey('buy-cart-category-shelf-${row.key}'),
            );
            expect(shelf, findsOneWidget);
            expect(
              find.descendant(of: shelf, matching: find.byType(BuyV2AddFace)),
              findsNWidgets(row.value.length),
            );
          }
        }
        for (final filter in ['shop', 'wholesale', 'bulk', 'all']) {
          final chip = find.byKey(ValueKey('buy-cart-filter-$filter'));
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pumpAndSettle();
          final visible = combination.visibleCartLines;
          final quantity = visible.fold<int>(
            0,
            (sum, line) => sum + line.quantity,
          );
          final trade =
              visible.isNotEmpty &&
              visible.every(
                (line) =>
                    line.product.destination == BuyV2Destination.wholesale,
              );
          final contextLabel = switch (filter) {
            'shop' => 'Shop · ',
            'wholesale' => 'Wholesale · ',
            'bulk' => 'Bulk · ',
            _ => '',
          };
          final quantityLabel = trade
              ? '$quantity ${quantity == 1 ? 'pack' : 'packs'}'
              : '$quantity ${quantity == 1 ? 'item' : 'items'}';
          final header = tester.widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-header-value-motion')),
          );
          expect(
            header.text,
            '$contextLabel${visible.length} ${visible.length == 1 ? 'product' : 'products'} · $quantityLabel',
            reason: 'Combination $mask / $filter',
          );
          expect(combination.scopedPayableTotal, payable);
          final hidden = combination.cartLines.length - visible.length;
          expect(
            find.byKey(const ValueKey('buy-cart-view-hidden-selection')),
            hidden > 0 ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
        for (final line in combination.cartLines.toList()) {
          combination.selectCartProduct(line.product.id, false);
        }
        await tester.pumpAndSettle();
        expect(find.text('Select products to checkout'), findsOneWidget);
        expect(combination.visibleCartLines, isNotEmpty);
        await tester.pumpWidget(const SizedBox());
        combination.dispose();
        combinationCore.dispose();
      }
    });
  }

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == destination &&
            !candidate.requiresPrescription,
      );

  for (final scale in [1.0, 2.0]) {
    for (final multiple in [false, true]) {
      testWidgets(
        'Cart action strip destinations preserve basket $scale multiple=$multiple',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 780));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          session.addProduct('s-tomato');
          if (multiple) session.addProduct('w-notebook');
          session.openCart();
          final quantity = session.itemCount;
          final total =
              session.totalForDestination(BuyV2Destination.shop) +
              session.totalForDestination(BuyV2Destination.wholesale);
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          Future<void> tapAction(String key) async {
            final target = find.byKey(ValueKey(key));
            await showInMainCartList(tester, target);
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            await tester.tap(target);
            await tester.pumpAndSettle();
          }

          await tapAction('buy-cart-browse-more');
          expect(session.view, BuyV2View.catalogue);
          await tester.tap(
            find.byKey(const ValueKey('buy-cart-navigation-button')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-cart-filter-all')));
          await tester.pumpAndSettle();
          await tapAction('buy-cart-compare-prices');
          if (multiple) {
            expect(find.text('Choose a product to compare'), findsOneWidget);
            await tester.tap(
              find.byKey(const ValueKey('buy-cart-compare-product-s-tomato')),
            );
            await tester.pumpAndSettle();
          }
          final sheet = find.byKey(
            const ValueKey('buy-product-comparison-sheet'),
          );
          expect(sheet, findsOneWidget);
          Navigator.of(tester.element(sheet)).pop();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          await tapAction('buy-cart-browse-offers');
          expect(find.byType(BuyV2OffersView), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('buy-cart-navigation-button')),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          expect(session.itemCount, quantity);
          expect(
            session.totalForDestination(BuyV2Destination.shop) +
                session.totalForDestination(BuyV2Destination.wholesale),
            total,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final viewport in [const Size(320, 711), const Size(711, 320)]) {
    for (final scope in BuyV2CartScope.values) {
      testWidgets(
        'R665 D01 Cart confirmation stays reachable text2 $viewport $scope',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport;
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          for (final destination in [
            BuyV2Destination.shop,
            BuyV2Destination.wholesale,
            BuyV2Destination.medicine,
          ]) {
            session.addProduct(productFor(destination).id);
          }
          session.openCart(scope: scope);
          final totalBefore = session.itemCount;
          final removedCount =
              session.usesMixedCartSelection || scope == BuyV2CartScope.all
              ? session.itemCount
              : session.countForDestination(switch (scope) {
                  BuyV2CartScope.shop => BuyV2Destination.shop,
                  BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
                  BuyV2CartScope.medicine => BuyV2Destination.medicine,
                  BuyV2CartScope.all => throw StateError('handled above'),
                });
          expect(removedCount, greaterThan(0));
          await tester.pumpWidget(app(session, textScale: 2));
          await tester.pumpAndSettle();
          session.openCart(scope: scope);
          await tester.pumpAndSettle();
          final open = find.byKey(const ValueKey('buy-cart-empty'));
          await tester.ensureVisible(open);
          await tester.pumpAndSettle();
          await tester.tap(open);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final keep = find.byKey(const ValueKey('buy-cart-clear-cancel'));
          final remove = find.byKey(const ValueKey('buy-cart-clear-confirm'));
          await tester.ensureVisible(keep);
          await tester.pumpAndSettle();
          expect(keep.hitTestable(), findsOneWidget);
          await tester.tap(keep);
          await tester.pumpAndSettle();
          expect(session.itemCount, totalBefore);
          expect(session.cartScope, scope);
          await tester.tap(open);
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding(bottom: 100);
          await tester.pumpAndSettle();
          await tester.ensureVisible(remove);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(remove).bottom,
            lessThanOrEqualTo(viewport.height - 100 - 24),
          );
          expect(tester.takeException(), isNull);
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          await tester.ensureVisible(remove);
          await tester.pumpAndSettle();
          expect(remove.hitTestable(), findsOneWidget);
          final button = tester.getRect(remove);
          expect(button.top, greaterThanOrEqualTo(24));
          expect(button.bottom, lessThanOrEqualTo(viewport.height - 24));
          await tester.tap(remove);
          await tester.pumpAndSettle();
          expect(session.itemCount, totalBefore - removedCount);
          expect(
            find.byKey(const ValueKey('buy-cart-clear-sheet')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final reduced in [false, true]) {
      testWidgets(
        'R66 028 main Cart money transitions fit Redmi360 text$scale reduced$reduced',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          tester.view.viewPadding = const FakeViewPadding(bottom: 32);
          addTearDown(tester.view.reset);
          final session = _R66PayableDisplayFixture(1);
          addTearDown(session.dispose);
          addTearDown(session.core.dispose);
          session.addProduct('w-notebook');
          session.openCart(scope: BuyV2CartScope.wholesale);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: reduced,
                ),
                child: child!,
              ),
              home: BuyV2Screen(
                session: session,
                initialDestination: session.destination,
                initialView: session.view,
              ),
            ),
          );
          await tester.pumpAndSettle();
          var quantity = 1;
          for (final total in [3480, 10000000, 1]) {
            session.setDisplayTotal(total);
            session.addProduct('w-notebook');
            quantity += 1;
            await tester.pump();
            for (final elapsed in [0, 50, 80, 200]) {
              await tester.pump(Duration(milliseconds: elapsed));
              for (final key in [
                'buy-cart-payable-total-motion',
                'buy-cart-line-total-motion-w-notebook',
                'buy-cart-line-quantity-motion-w-notebook',
              ]) {
                final owner = find.byKey(ValueKey(key));
                final value = tester.widget<BuyV2FiniteValueTransition>(owner);
                final expected = key.contains('line-total')
                    ? buyV2Money(3480 * quantity)
                    : key.contains('line-quantity')
                    ? '$quantity'
                    : buyV2Money(total);
                expect(value.text, expected, reason: key);
                final paragraphs = find.descendant(
                  of: owner,
                  matching: find.byType(RichText),
                );
                expect(paragraphs, findsOneWidget);
                final opacity = tester.widget<Opacity>(
                  find.descendant(of: owner, matching: find.byType(Opacity)),
                );
                if (reduced || elapsed == 200) {
                  expect(opacity.opacity, 1);
                } else if (elapsed == 0) {
                  expect(opacity.opacity, lessThan(1));
                }
                for (final paragraph
                    in tester.renderObjectList<RenderParagraph>(paragraphs)) {
                  expect(paragraph.text.toPlainText(), expected);
                  final natural = TextPainter(
                    text: paragraph.text,
                    textDirection: paragraph.textDirection,
                    textScaler: paragraph.textScaler,
                  )..layout(maxWidth: paragraph.size.width);
                  expect(
                    paragraph.didExceedMaxLines,
                    isFalse,
                    reason:
                        '$key current=${value.text} painted=${paragraph.text.toPlainText()} '
                        'width=${paragraph.size.width} elapsed=$elapsed total=$total',
                  );
                  expect(
                    paragraph.size.height,
                    greaterThanOrEqualTo(natural.height - .1),
                    reason: key,
                  );
                  natural.dispose();
                }
              }
              expect(tester.takeException(), isNull);
            }
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }

  for (final width in [320.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final total in [3480, 10000000]) {
        testWidgets(
          'R66 Cart payable display INR$total fits $width at $scale',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 800));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final session = _R66PayableDisplayFixture(total);
            addTearDown(session.dispose);
            session.addProduct('w-notebook');
            session.openCart(scope: BuyV2CartScope.wholesale);
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: _r66CartCaptureBoundary(child!),
                ),
                home: Scaffold(
                  body: BuyV2CartView(session: session, onBrowseMore: () {}),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final amount = find.byKey(
              const ValueKey('buy-cart-payable-total-motion'),
            );
            final value = tester.widget<BuyV2FiniteValueTransition>(amount);
            final required = buyV2ValueTextSize(
              tester.element(amount),
              value.text,
              value.style,
            );
            expect(value.text, buyV2Money(total));
            expect(value.ownerSize.width, greaterThanOrEqualTo(required.width));
            expect(
              value.ownerSize.height,
              greaterThanOrEqualTo(required.height),
            );
            expect(
              tester.getSize(amount).width,
              greaterThanOrEqualTo(required.width),
            );
            expect(
              tester.getSize(amount).height,
              greaterThanOrEqualTo(required.height),
            );
            final bar = tester.getRect(
              find.byKey(const ValueKey('buy-cart-action-bar')),
            );
            expect(tester.getRect(amount).left, greaterThanOrEqualTo(bar.left));
            expect(tester.getRect(amount).right, lessThanOrEqualTo(bar.right));
            final review = find.widgetWithText(FilledButton, 'Checkout');
            expect(tester.getSize(review).height, greaterThanOrEqualTo(44));
            final label = find.descendant(
              of: review,
              matching: find.text('Checkout'),
            );
            expect(
              tester.getSize(review).height,
              greaterThanOrEqualTo(tester.getSize(label).height),
            );
            expect(tester.getBottomRight(review).dy, lessThanOrEqualTo(800));
            for (final scope in ['all', 'shop', 'wholesale', 'bulk']) {
              final control = find.byKey(ValueKey('buy-cart-filter-$scope'));
              await tester.ensureVisible(control);
              await tester.pumpAndSettle();
              expect(control.hitTestable(), findsOneWidget);
              expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
            }
            await _captureR66MainCart(
              tester,
              'total$total-width$width-text$scale',
            );
            final bill = find.byKey(const ValueKey('buy-cart-bill-summary'));
            await showInMainCartList(tester, bill);
            final billAmount = find.descendant(
              of: bill,
              matching: find.text(buyV2Money(total)),
            );
            expect(billAmount, findsAtLeastNWidgets(1));
            for (var index = 0; index < billAmount.evaluate().length; index++) {
              final item = billAmount.at(index);
              expect(
                tester.getRect(item).left,
                greaterThanOrEqualTo(tester.getRect(bill).left),
              );
              expect(
                tester.getRect(item).right,
                lessThanOrEqualTo(tester.getRect(bill).right),
              );
              expect(
                tester.renderObject<RenderParagraph>(item).didExceedMaxLines,
                isFalse,
              );
            }
            if (scale == 2 && total == 10000000) {
              await _captureR66MainCart(tester, 'bill-width$width-text$scale');
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    testWidgets('R66 Cart item values fit enlarged ${destination.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final id = destination == BuyV2Destination.shop
          ? 's-tomato'
          : 'w-notebook';
      session.addProduct(id);
      session.openCart(
        scope: destination == BuyV2Destination.shop
            ? BuyV2CartScope.shop
            : BuyV2CartScope.wholesale,
      );
      await tester.pumpWidget(app(session, textScale: 2));
      await tester.pumpAndSettle();
      for (final kind in ['total', 'quantity']) {
        final finder = find.byKey(ValueKey('buy-cart-line-$kind-motion-$id'));
        final value = tester.widget<BuyV2FiniteValueTransition>(finder);
        final required = buyV2ValueTextSize(
          tester.element(finder),
          value.text,
          value.style,
        );
        expect(value.ownerSize.width, greaterThanOrEqualTo(required.width));
        expect(value.ownerSize.height, greaterThanOrEqualTo(required.height));
        expect(
          tester.getSize(finder).width,
          greaterThanOrEqualTo(required.width),
        );
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(required.height),
        );
      }
      await _captureR66MainCart(
        tester,
        'item-${destination.name}-text2-values',
      );
      for (final key in [
        'buy-cart-header-value-motion',
        'buy-cart-filter-all',
        'buy-cart-filter-shop',
        'buy-cart-filter-wholesale',
        'buy-cart-coupons',
      ]) {
        final finder = find.byKey(ValueKey(key));
        if (finder.evaluate().isEmpty) {
          await showInMainCartList(tester, finder);
        }
        expect(finder, findsOneWidget);
        final texts = find.descendant(
          of: finder,
          matching: find.byType(RichText),
        );
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          texts,
        )) {
          expect(paragraph.didExceedMaxLines, isFalse, reason: key);
          final text = paragraph.text.toPlainText();
          final painter = TextPainter(
            text: paragraph.text,
            textDirection: TextDirection.ltr,
            textScaler: const TextScaler.linear(2),
          )..layout(maxWidth: paragraph.size.width);
          expect(
            tester.getSize(finder).height,
            greaterThanOrEqualTo(painter.height),
            reason: '$key: $text',
          );
          painter.dispose();
        }
      }
      final browse = find.byKey(const ValueKey('buy-cart-browse-more'));
      await showInMainCartList(tester, browse, scrollDelta: -450);
      final browseText = find.descendant(
        of: browse,
        matching: find.text('Browse more products'),
      );
      expect(
        tester.getRect(browseText).top,
        greaterThanOrEqualTo(tester.getRect(browse).top),
      );
      expect(
        tester.getRect(browseText).bottom,
        lessThanOrEqualTo(tester.getRect(browse).bottom),
      );
      await _captureR66MainCart(tester, 'item-${destination.name}-text2');
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    testWidgets('R66 empty Cart fits compact enlarged ${destination.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      session.openDestination(destination);
      session.openCart();
      var browseCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: _r66CartCaptureBoundary(child!),
          ),
          home: Scaffold(
            body: BuyV2CartView(
              session: session,
              onBrowseMore: () => browseCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('buy-empty-cart-browse'));
      expect(action, findsOneWidget);
      final labels = find.descendant(of: action, matching: find.byType(Text));
      expect(labels, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(labels);
      final naturalLabel = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
        textScaler: const TextScaler.linear(2),
      )..layout(maxWidth: paragraph.size.width);
      expect(paragraph.size.height, greaterThanOrEqualTo(naturalLabel.height));
      naturalLabel.dispose();
      expect(
        tester.getRect(labels).top,
        greaterThanOrEqualTo(tester.getRect(action).top),
      );
      expect(
        tester.getRect(labels).bottom,
        lessThanOrEqualTo(tester.getRect(action).bottom),
      );
      expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Browse products'), findsOneWidget);
      expect(find.textContaining('₹ Total products'), findsNothing);
      final header = tester.widget<BuyV2FiniteValueTransition>(
        find.byKey(const ValueKey('buy-cart-header-value-motion')),
      );
      expect(header.text, isNot(contains('·  ·')));
      expect(tester.takeException(), isNull);
      await _captureR66MainCart(tester, 'empty-${destination.name}-text2');
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(browseCount, 1);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'custom shared delivery note editor saves clears and preserves basket $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.addProduct('s-tomato');
        session.addProduct('w-notebook');
        session.openCart(scope: BuyV2CartScope.all);
        final originalTotal = session.cartTotal;
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        final edit = find.byKey(
          const ValueKey('buy-cart-instruction-custom-delivery'),
        );
        await showInMainCartList(tester, edit);
        await tester.ensureVisible(edit);
        expect(
          find.descendant(of: edit, matching: find.text('Add instructions')),
          findsOneWidget,
        );
        expect(
          tester.widget<TextButton>(edit).style!.foregroundColor!.resolve({}),
          BuyV2ActionStyle.primaryForeground,
        );
        expect(
          tester
              .widget<TextButton>(edit)
              .style!
              .textStyle!
              .resolve({})!
              .fontSize,
          11,
        );
        await tester.tap(edit);
        await tester.pumpAndSettle();
        final field = find.byKey(
          const ValueKey('buy-cart-instruction-note-delivery'),
        );
        await tester.enterText(field, 'Use the side entrance');
        final save = find.byKey(
          const ValueKey('buy-cart-instruction-save-delivery'),
        );
        final composer = find.byKey(
          const ValueKey('buy-cart-instruction-composer-delivery'),
        );
        void expectEditorVisible() {
          final viewport = tester.getRect(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                )
                .first,
          );
          expect(
            tester.getRect(field).top,
            greaterThanOrEqualTo(viewport.top),
            reason:
                'Viewport $viewport; composer ${tester.getRect(composer)}; '
                'field ${tester.getRect(field)}; Save ${tester.getRect(save)}',
          );
          expect(
            tester.getRect(save).bottom,
            lessThanOrEqualTo(viewport.bottom),
          );
          expect(
            tester.getRect(composer).bottom,
            lessThanOrEqualTo(viewport.bottom),
          );
          expect(save.hitTestable(), findsOneWidget);
          expect(
            find
                .descendant(of: composer, matching: find.text('Cancel'))
                .hitTestable(),
            findsOneWidget,
          );
          expect(session.cartTotal, originalTotal);
        }

        // Focus occurs before the IME reaches its final size. No manual
        // ensureVisible call may repair the editor under test.
        for (final inset in [170.0, 300.0]) {
          tester.view.viewInsets = FakeViewPadding(bottom: inset);
          await tester.pumpAndSettle();
          expectEditorVisible();
        }
        await tester.enterText(
          field,
          'Use the side entrance\nCall when you arrive\nHand to the recipient',
        );
        await tester.pumpAndSettle();
        expectEditorVisible();
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          contains('Hand to the recipient'),
        );
        await tester.tap(field);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expectEditorVisible();
        await tester.enterText(field, 'Use the side entrance');
        await tester.pumpAndSettle();
        final draftController = tester.widget<TextField>(field).controller;
        session.chooseCartDisplayFilter('wholesale');
        await tester.pumpAndSettle();
        await showInMainCartList(tester, field);
        expect(
          tester.widget<TextField>(field).controller,
          same(draftController),
        );
        expect(draftController!.text, 'Use the side entrance');
        session.chooseCartDisplayFilter('all');
        await tester.pumpAndSettle();
        await showInMainCartList(tester, field);
        final composerRect = tester.getRect(composer);
        final fieldRect = tester.getRect(field);
        final saveRect = tester.getRect(save);
        expect(composerRect.contains(saveRect.center), isTrue);
        expect(saveRect.top - fieldRect.bottom, lessThanOrEqualTo(4));
        expect(
          find.descendant(of: composer, matching: find.text('Clear')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: composer, matching: find.text('Cancel')),
          findsOneWidget,
        );
        await tester.tap(save);
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(
          session.customDeliveryInstructionFor(BuyV2Destination.shop),
          'Use the side entrance',
        );
        expect(
          session.deliveryInstructionTextFor(BuyV2Destination.wholesale),
          'Use the side entrance',
        );
        expect(
          find.byKey(const ValueKey('buy-cart-instruction-saved-delivery')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: edit, matching: find.text('Add instructions')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-cart-instruction-delivery-none')),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('buy-cart-instruction-clear-draft-delivery'),
          ),
          findsNothing,
        );
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expectEditorVisible();
        final clearDraft = find.byKey(
          const ValueKey('buy-cart-instruction-clear-draft-delivery'),
        );
        await tester.tap(clearDraft);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(
          session.customDeliveryInstructionFor(BuyV2Destination.shop),
          'Use the side entrance',
        );
        await tester.tap(
          find.descendant(of: composer, matching: find.text('Cancel')),
        );
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(
          session.customDeliveryInstructionFor(BuyV2Destination.shop),
          'Use the side entrance',
        );
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Use the side entrance',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expectEditorVisible();
        await tester.tap(clearDraft);
        await tester.pumpAndSettle();
        await tester.tap(save);
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(
          session.deliveryInstructionTextFor(BuyV2Destination.shop),
          isNull,
        );
        expect(
          session.deliveryInstructionTextFor(BuyV2Destination.wholesale),
          isNull,
        );
        expect(
          find.byKey(const ValueKey('buy-cart-instruction-saved-delivery')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        expect(session.cartTotal, originalTotal);
        // A queued keyboard callback cannot act on a disposed Cart editor.
        await tester.tap(edit);
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('Compact delivery radio mixed basket shared instruction $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final semantics = tester.ensureSemantics();

      session.addProduct('s-tomato');
      session.addProduct('w-notebook');
      session.openCart(scope: BuyV2CartScope.all);
      final total = session.cartTotal;
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-instruction-context-shop')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-instruction-context-wholesale')),
        findsNothing,
      );
      const destination = BuyV2Destination.shop;
      final owner = find.byKey(
        const ValueKey('buy-cart-delivery-instructions-delivery'),
      );
      {
        await showInMainCartList(tester, owner);
        expect(find.text('Add instructions'), findsOneWidget);
        expect(find.text('Delivery instructions · optional'), findsOneWidget);
        final cue = find.byKey(ValueKey('buy-instruction-scroll-cue-delivery'));
        final lane = find.byKey(
          PageStorageKey('buy-instruction-lane-delivery'),
        );
        final scrollbar = tester.widget<RawScrollbar>(cue);
        final position = scrollbar.controller!.position;
        expect(scrollbar.thumbVisibility, isTrue);
        expect(scrollbar.interactive, isFalse);
        expect(scrollbar.thumbColor, BuyV2Colors.muted);
        expect(position.maxScrollExtent, greaterThan(0));
        expect(tester.getSize(cue).height, tester.getSize(lane).height);
        expect(tester.getSize(cue).height, 48);
        await tester.drag(lane, Offset(-position.maxScrollExtent - 100, 0));
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(position.maxScrollExtent, 0.5));
        final lastOption = session.deliveryInstructionsFor(destination).last;
        final lastAction = find.byKey(
          ValueKey('buy-cart-instruction-delivery-${lastOption.id}'),
        );
        expect(
          tester.getRect(lastAction).right,
          lessThanOrEqualTo(tester.getRect(cue).right + 0.5),
        );
        expect(session.selectedDeliveryInstructionFor(destination), isNull);
        expect(session.cartTotal, total);
        await tester.drag(lane, Offset(position.maxScrollExtent + 100, 0));
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(position.minScrollExtent, 0.5));
        final option = session.deliveryInstructionsFor(destination).first;
        final action = find.byKey(
          ValueKey('buy-cart-instruction-delivery-${option.id}'),
        );
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(tester.getSize(action).height, inInclusiveRange(48, 55));
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          session.selectedDeliveryInstructionFor(destination)?.id,
          option.id,
        );
        expect(
          tester.getSemantics(action),
          matchesSemantics(
            isChecked: true,
            hasCheckedState: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            label: 'Delivery instructions: ${option.label}',
          ),
        );
      }
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.wholesale)?.id,
        session.selectedDeliveryInstructionFor(BuyV2Destination.shop)?.id,
      );
      session.openCart(scope: BuyV2CartScope.shop);
      await tester.pumpAndSettle();
      final shop = find.byKey(
        const ValueKey('buy-cart-delivery-instructions-delivery'),
      );
      await showInMainCartList(tester, shop);
      expect(
        find.byKey(const ValueKey('buy-cart-instruction-delivery-none')),
        findsNothing,
      );
      expect(find.text('Clear'), findsNothing);
      final addInstructions = find.byKey(
        const ValueKey('buy-cart-instruction-custom-delivery'),
      );
      await tester.ensureVisible(addInstructions);
      await tester.pumpAndSettle();
      await tester.tap(addInstructions);
      await tester.pumpAndSettle();
      final clear = find.byKey(
        const ValueKey('buy-cart-instruction-clear-draft-delivery'),
      );
      expect(find.text('Clear'), findsOneWidget);
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.shop),
        isNotNull,
      );
      final saveInstructions = find.byKey(
        const ValueKey('buy-cart-instruction-save-delivery'),
      );
      await tester.ensureVisible(saveInstructions);
      await tester.pumpAndSettle();
      await tester.tap(saveInstructions);
      await tester.pumpAndSettle();
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.shop),
        isNull,
      );
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.wholesale),
        isNull,
      );
      session.openCart(scope: BuyV2CartScope.all);
      await tester.pumpAndSettle();
      expect(session.cartTotal, total);
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.wholesale),
        isNull,
      );
      await tester.binding.setSurfaceSize(const Size(2200, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: Scaffold(
            body: BuyV2CartView(session: session, onBrowseMore: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await showInMainCartList(tester, shop);
      final fittingCue = tester.widget<RawScrollbar>(
        find.byKey(const ValueKey('buy-instruction-scroll-cue-delivery')),
      );
      // Flutter's scrollbar suppresses its thumb when the lane has no overflow.
      expect(fittingCue.controller!.position.maxScrollExtent, 0);
      await tester.drag(
        find.byKey(const PageStorageKey('buy-instruction-lane-delivery')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(fittingCue.controller!.position.pixels, 0);
      expect(session.cartTotal, total);
      expect(
        session.selectedDeliveryInstructionFor(BuyV2Destination.shop),
        isNull,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    testWidgets(
      'R66 delivery instructions stay complete at 200 percent ${destination.name}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = BuyV2Session(core: BuySession());
        addTearDown(session.dispose);
        session.addProduct(
          destination == BuyV2Destination.shop ? 's-tomato' : 'w-notebook',
        );
        session.openCart();
        await tester.pumpWidget(app(session, textScale: 2));
        await tester.pumpAndSettle();
        if (destination == BuyV2Destination.wholesale) {
          expect(find.textContaining('Minimum order 1 pack ·'), findsOneWidget);
          expect(find.textContaining('Minimum order 1 packs'), findsNothing);
        }
        final owner = find.byKey(
          ValueKey('buy-cart-delivery-instructions-delivery'),
        );
        await showInMainCartList(tester, owner);
        final lane = find.descendant(
          of: owner,
          matching: find.byType(Scrollable),
        );
        expect(lane, findsOneWidget);
        await _captureR66MainCart(
          tester,
          'instructions-${destination.name}-text2',
        );
        for (final option in session.deliveryInstructionsFor(destination)) {
          final action = find.byKey(
            ValueKey('buy-cart-instruction-delivery-${option.id}'),
          );
          await tester.scrollUntilVisible(
            action,
            110,
            scrollable: lane,
            maxScrolls: 25,
          );
          await tester.pumpAndSettle();
          final label = find.descendant(
            of: action,
            matching: find.text(option.label),
          );
          expect(label, findsOneWidget);
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
            reason: option.label,
          );
          expect(
            tester.getRect(label).bottom,
            lessThanOrEqualTo(tester.getRect(action).bottom),
          );
          expect(
            tester.getRect(label).top,
            greaterThanOrEqualTo(tester.getRect(action).top),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'REG4628 Cart preserves illustration and whole title words at 200 percent',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      const id = 'm-paracetamol-500';
      session.addProduct(id);
      session.openCart();
      final quantity = session.quantityFor(id);
      final total = session.cartTotal;
      await tester.pumpWidget(app(session, textScale: 2));
      await tester.pumpAndSettle();
      final summary = find.byKey(
        const ValueKey('buy-cart-product-summary-$id'),
      );
      final title = find.descendant(
        of: summary,
        matching: find.text(session.product(id).customerTitle),
      );
      await showInMainCartList(tester, title);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      expect(boxes, isNotEmpty);
      expect(
        boxes.map((box) => box.top).toSet(),
        hasLength(1),
        reason: 'Paracetamol must not split inside its word',
      );
      final photo = find.byKey(const ValueKey('buy-cart-packshot-$id'));
      expect(
        find.descendant(
          of: photo,
          matching: find.byKey(const ValueKey('buy-product-illustration-$id')),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.quantityFor(id), quantity);
      expect(session.cartTotal, total);
    },
  );

  testWidgets('mixed Cart uses real media and context-specific benefit pages', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final products = [
      productFor(BuyV2Destination.shop),
      productFor(BuyV2Destination.wholesale),
      productFor(BuyV2Destination.medicine),
    ];
    for (final product in products) {
      session.addProduct(product.id);
    }
    session.openCart();
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-cart-empty')), findsOneWidget);
    expect(find.byTooltip('Empty entire cart'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);

    for (final product in products) {
      final packshot = find.byKey(ValueKey('buy-cart-packshot-${product.id}'));
      await showInMainCartList(tester, packshot);
      expect(packshot, findsOneWidget);
      final save = find.byKey(ValueKey('buy-save-${product.id}'));
      expect(save, findsOneWidget);
      expect(
        tester.getRect(save).bottom,
        lessThanOrEqualTo(tester.getRect(packshot).top),
      );
      expect(tester.getSize(packshot).width, greaterThanOrEqualTo(76));
      expect(tester.getSize(packshot).width, tester.getSize(packshot).height);
      expect(
        find.descendant(
          of: packshot,
          matching: find.byKey(
            ValueKey('buy-product-illustration-${product.id}'),
          ),
        ),
        findsOneWidget,
      );
      final quantity = session.quantityFor(product.id);
      final wasSaved = session.isSaved(product.id);
      await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(session.isSaved(product.id), !wasSaved);
      expect(session.quantityFor(product.id), quantity);
      expect(find.byKey(const ValueKey('buy-cart-empty')), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(session.isSaved(product.id), wasSaved);
    }
    expect(find.text('Shop order'), findsNothing);
    expect(find.text('Wholesale order'), findsNothing);
    expect(find.text('Medicine order'), findsNothing);

    tester
        .state<ScrollableState>(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
    await showInMainCartList(tester, coupons);
    expect(coupons, findsOneWidget);
    expect(find.byKey(const ValueKey('buy-cart-coupons')), findsOneWidget);
    expect(find.textContaining('Tip Shop delivery partner'), findsNothing);
    expect(find.textContaining('Tip pharmacy delivery partner'), findsNothing);

    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-cart-benefits-inline')),
        matching: find.textContaining('Shop ·'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-cart-coupon-empty-shop')),
      findsOneWidget,
    );
    expect(find.text('No Shop coupons right now'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-paymentOffer-empty-shop')),
      findsOneWidget,
    );
    expect(find.text('No Shop payment offers right now'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-cart-benefit-destination-wholesale')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-destination-wholesale')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-cart-benefits-inline')),
        matching: find.textContaining('Wholesale ·'),
      ),
      findsOneWidget,
    );
    expect(find.text('No trade payment offers right now'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-cart-benefit-destination-medicine')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-destination-medicine')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-cart-benefits-inline')),
        matching: find.textContaining('Medicine ·'),
      ),
      findsOneWidget,
    );
    expect(find.text('No Medicine payment offers right now'), findsOneWidget);

    await tester.ensureVisible(coupons);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(coupons);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-cart-coupons')), findsOneWidget);
  });

  testWidgets(
    'device-review offer UI selects and removes all six seeded states',
    (tester) async {
      Future<void> revealHeader(Finder target) async {
        await tester.scrollUntilVisible(
          target,
          -180,
          scrollable: find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first,
          maxScrolls: 30,
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
      }

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: const ActiveTestCartBenefits(),
      );
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        session.addProduct(productFor(destination).id);
      }
      // Each coupon is scoped to its own destination. Populate qualifying
      // baskets for this selection/removal test rather than relying on the
      // combined total of unrelated destinations.
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final product = productFor(destination);
        final minimum = destination == BuyV2Destination.wholesale ? 2500 : 499;
        if (session.totalForDestination(destination) < minimum) {
          expect(
            session.setCartQuantity(
              product.id,
              ((minimum + product.price - 1) ~/ product.price).toString(),
            ),
            isTrue,
          );
        }
      }
      final originalTotal = session.cartTotal;
      session.openCart();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
      await showInMainCartList(tester, coupons);
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final destinationControl = find.byKey(
          ValueKey('buy-cart-benefit-destination-${destination.name}'),
        );
        await revealHeader(destinationControl);
        await tester.tap(destinationControl);
        await tester.pumpAndSettle();
        for (final kind in BuyV2CartBenefitKind.values) {
          final kindControl = find.byKey(
            ValueKey(
              'buy-cart-benefit-kind-'
              '${kind == BuyV2CartBenefitKind.coupon ? 'coupon' : 'payment'}',
            ),
          );
          await revealHeader(kindControl);
          await tester.tap(kindControl);
          await tester.pumpAndSettle();
          final benefitId = '${destination.name}-${kind.name}';
          final card = find.byKey(ValueKey('buy-cart-benefit-$benefitId'));
          expect(card, findsOneWidget);
          expect(
            find.byKey(ValueKey('buy-cart-benefit-$benefitId-2')),
            findsOneWidget,
          );
          expect(
            find.byKey(ValueKey('buy-cart-benefit-$benefitId-3')),
            findsOneWidget,
          );
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(card).dy, lessThan(220));
          final list = find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first;
          expect(
            tester.getSize(card).height,
            lessThan(tester.getSize(list).height),
          );
          for (final element
              in find
                  .descendant(of: card, matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            expect(paragraph.didExceedMaxLines, isFalse);
            final natural = TextPainter(
              text: paragraph.text,
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
            )..layout(maxWidth: paragraph.size.width);
            expect(
              paragraph.size.height + .1,
              greaterThanOrEqualTo(natural.height),
            );
            natural.dispose();
          }
          final select = find.byKey(
            ValueKey('buy-cart-benefit-select-$benefitId'),
          );
          await tester.ensureVisible(select);
          await tester.pumpAndSettle();
          expect(select.hitTestable(), findsOneWidget);
          expect(tester.getSize(select).height, greaterThanOrEqualTo(44));
          await tester.tap(select);
          await tester.pumpAndSettle();
          expect(
            session.selectedCartBenefit(kind: kind, destination: destination),
            isNotNull,
          );
          final remove = find.byKey(
            ValueKey('buy-cart-benefit-remove-$benefitId'),
          );
          await tester.ensureVisible(remove);
          await tester.pumpAndSettle();
          expect(remove.hitTestable(), findsOneWidget);
          expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
          await tester.tap(remove);
          await tester.pumpAndSettle();
          expect(
            session.selectedCartBenefit(kind: kind, destination: destination),
            isNull,
          );
          expect(session.cartTotal, originalTotal);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'C08 Cart categories preserve exact Add Save and return at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final core = BuySession();
        final source = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 1,
          includeVariantReviewFixtures: true,
        );
        final session = BuyV2Session(core: core, cataloguePageSource: source);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.addProduct('s-tomato');
        session.addProduct('w-notebook');
        final pagedTomatoId = source.productIdAt(0, 0);
        expect(await session.openLinkedProduct(pagedTomatoId), isTrue);
        expect(session.addProduct(pagedTomatoId), isTrue);
        final phoneId = source.productIdAt(
          0,
          BuyV2Catalogue.products
              .where((product) => product.destination == BuyV2Destination.shop)
              .length,
        );
        expect(await session.openLinkedProduct(phoneId), isTrue);
        final phone = session.product(phoneId);
        expect(phone.hasStructuredVariants, isTrue);
        session.openCart();
        final total = session.cartTotal;
        final originalTradeQuantity = session.quantityFor('w-notebook');
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        final phoneCard = find.byKey(
          ValueKey('buy-cart-recommendation-$phoneId'),
        );
        await showInMainCartList(tester, phoneCard);
        await tester.ensureVisible(phoneCard);
        await tester.pumpAndSettle();
        for (final option in phone.variantAttributes) {
          expect(
            find.descendant(
              of: phoneCard,
              matching: find.textContaining(option.optionLabel),
            ),
            findsOneWidget,
            reason: 'Chosen ${option.dimensionLabel} is visible before Add',
          );
        }
        final category = find.byKey(
          const ValueKey('buy-cart-category-shop:fruits-vegetables'),
        );
        final categoryView = find.byKey(
          const ValueKey('buy-cart-category-view-shop:fruits-vegetables'),
        );
        await showInMainCartList(tester, categoryView);
        await tester.ensureVisible(categoryView);
        await tester.pumpAndSettle();
        expect(categoryView.hitTestable(), findsOneWidget);
        await tester.tap(categoryView);
        await tester.pumpAndSettle();
        await showInMainCartList(tester, category);
        expect(tester.widget<ChoiceChip>(category).selected, isTrue);
        expect(session.cartTotal, total);
        expect(session.cartDisplayFilter, 'all');
        final lane = find.byKey(
          const ValueKey('buy-cart-recommendations-shop'),
        );
        final cards = tester.widgetList<InkWell>(
          find.descendant(
            of: lane,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is InkWell &&
                  widget.key.toString().contains('buy-cart-recommendation-'),
            ),
          ),
        );
        expect(cards, isNotEmpty);
        final expected = session
            .cartRecommendationsFor(BuyV2Destination.shop, limit: 1000)
            .where((p) => p.categoryId == 'fruits-vegetables')
            .take(24)
            .toList();
        expect(cards.length, expected.length);
        expect(
          find.byKey(
            const ValueKey('buy-cart-category-wholesale:fruits-vegetables'),
          ),
          findsOneWidget,
          reason: 'Matching category IDs remain separate by purchase context',
        );
        final product = expected.first;
        final save = find.byKey(ValueKey('buy-save-${product.id}'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(tester.getSize(save), const Size(44, 44));
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(session.isSaved(product.id), isTrue);
        expect(session.cartTotal, total);
        final title = find.descendant(
          of: find.byKey(ValueKey('buy-cart-recommendation-${product.id}')),
          matching: find.text(product.customerTitle),
        );
        await tester.ensureVisible(title);
        await tester.pumpAndSettle();
        await tester.tap(title);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, product.id);
        session.goBack();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await showInMainCartList(tester, category);
        expect(tester.widget<ChoiceChip>(category).selected, isTrue);
        final add = find.byKey(ValueKey('buy-cart-add-${product.id}'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.quantityFor(product.id), product.minimumOrder);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.quantityFor('w-notebook'), originalTradeQuantity);
        expect(
          session.cartLines
              .firstWhere((line) => line.product.id == product.id)
              .product
              .isFromSameStoreAs(product),
          isTrue,
        );
        final allProducts = find.byKey(const ValueKey('buy-cart-category-all'));
        await tester.ensureVisible(allProducts);
        await tester.pumpAndSettle();
        expect(allProducts.hitTestable(), findsOneWidget);
        await tester.tap(allProducts);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(category).selected, isFalse);
        expect(tester.widget<ChoiceChip>(allProducts).selected, isTrue);
        final switcher = find.byKey(const ValueKey('buy-cart-deal-switch'));
        await showInMainCartList(tester, switcher);
        await tester.ensureVisible(switcher);
        await tester.pumpAndSettle();
        final beforeDeals = session.cartTotal;
        await tester.tap(switcher);
        await tester.pumpAndSettle();
        expect(find.text('Products'), findsOneWidget);
        expect(session.cartTotal, beforeDeals);
        expect(session.cartDisplayFilter, 'all');
        final dealCard = find.byKey(
          ValueKey('buy-cart-recommendation-$phoneId'),
        );
        await showInMainCartList(tester, dealCard);
        await tester.ensureVisible(dealCard);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('buy-cart-deal-$phoneId')), findsOneWidget);
        final dealTitle = find.descendant(
          of: dealCard,
          matching: find.text(phone.customerTitle),
        );
        await tester.tap(dealTitle);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, phoneId);
        session.goBack();
        await tester.pumpAndSettle();
        await showInMainCartList(tester, switcher);
        expect(
          find.text('Products'),
          findsOneWidget,
          reason: 'Deal view survives Product and Back',
        );
        await tester.ensureVisible(switcher);
        await tester.pumpAndSettle();
        await tester.tap(switcher);
        await tester.pumpAndSettle();
        expect(find.text('Explore products'), findsOneWidget);
        expect(session.cartTotal, beforeDeals);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        final pagingSource = _CartDiscoveryPagingSource();
        final pagingCore = BuySession();
        final pagingSession = BuyV2Session(
          core: pagingCore,
          cataloguePageSource: pagingSource,
        );
        addTearDown(pagingSession.dispose);
        addTearDown(pagingCore.dispose);
        pagingSession.chooseCatalogueArea(
          null,
          BuyV2CatalogueAreaScope.allAreas,
        );
        pagingSession.addProduct('s-tomato');
        pagingSession.openCart();
        await tester.pumpWidget(app(pagingSession, textScale: scale));
        await tester.pumpAndSettle();
        final pagingTotal = pagingSession.cartTotal;
        final retailChoice = find.byKey(
          const ValueKey('buy-cart-discovery-type-shop'),
        );
        await showInMainCartList(tester, retailChoice);
        expect(
          find.descendant(
            of: retailChoice,
            matching: find.text('Retail products'),
          ),
          findsOneWidget,
        );
        final more = find.byKey(const ValueKey('buy-cart-discovery-more'));
        Future<void> moreProducts() async {
          await showInMainCartList(tester, more);
          await tester.ensureVisible(more);
          await tester.pumpAndSettle();
          expect(
            find.ancestor(
              of: more,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    axisDirectionToAxis(widget.axisDirection) ==
                        Axis.horizontal,
              ),
            ),
            findsNothing,
            reason:
                'More products is below the rows, never hidden at a sideways lane end',
          );
          final discovery = find.byKey(
            const PageStorageKey('buy-cart-discovery'),
          );
          final cards = find.descendant(
            of: discovery,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is InkWell &&
                  widget.key.toString().contains('buy-cart-recommendation-'),
            ),
          );
          for (final card in cards.evaluate()) {
            expect(
              tester.getTopLeft(more).dy + .1,
              greaterThanOrEqualTo(
                tester.getBottomRight(find.byKey(card.widget.key!)).dy,
              ),
            );
          }
          expect(more.hitTestable(), findsOneWidget);
          await tester.tap(more);
          await tester.pumpAndSettle();
          expect(pagingSession.cartTotal, pagingTotal);
          expect(pagingSession.quantityFor('s-tomato'), 1);
        }

        pagingSource.failNext = true;
        for (
          var attempt = 0;
          attempt < 12 && pagingSource.requests == 0;
          attempt++
        ) {
          await moreProducts();
        }
        expect(pagingSource.requests, 1);
        expect(find.text('Try again'), findsOneWidget);
        await moreProducts();
        expect(pagingSource.requests, 2);
        expect(pagingSource.lastQuery?.query, isEmpty);
        expect(pagingSource.lastQuery?.shopSaleType, isNull);
        expect(
          pagingSource.lastQuery?.areaScope,
          BuyV2CatalogueAreaScope.allAreas,
        );
        expect(
          pagingSource.lastTotal,
          greaterThan(40),
          reason: 'The review cohort must cross a real catalogue cursor',
        );
        for (
          var attempt = 0;
          attempt < 12 && pagingSource.requests < 3;
          attempt++
        ) {
          await moreProducts();
        }
        expect(pagingSource.requests, 3);
        final pagingScope = 'cart-explore-${pagingSession.cartScope.name}-shop';
        final pager = pagingSession.acquireCatalogueProducts(pagingScope);
        expect(pager.page?.startIndex, greaterThan(0));
        expect(
          pager.retainedItemCount,
          lessThanOrEqualTo(pager.pageSize * pager.maximumCachedPages),
        );
        pagingSession.releaseCatalogueProducts(pagingScope);
        expect(pagingSource.productObjectsCreated, lessThan(200));
        final hold = Completer<void>();
        pagingSource.holdNext = hold.future;
        for (
          var attempt = 0;
          attempt < 12 && pagingSource.requests < 4;
          attempt++
        ) {
          await showInMainCartList(tester, more);
          await tester.ensureVisible(more);
          await tester.pumpAndSettle();
          await tester.tap(more);
          await tester.pump();
        }
        expect(pagingSource.requests, 4);
        final wholesaleChoice = find.byKey(
          const ValueKey('buy-cart-discovery-type-wholesale'),
        );
        await showInMainCartList(tester, wholesaleChoice);
        await tester.ensureVisible(wholesaleChoice);
        await tester.pumpAndSettle();
        await tester.tap(wholesaleChoice);
        await tester.pump();
        hold.complete();
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(wholesaleChoice).selected, isTrue);
        expect(pagingSession.cartTotal, pagingTotal);
        expect(pagingSession.cartDisplayFilter, 'all');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Wholesale Cart keeps trade vocabulary and truthful summary', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final wholesale = productFor(BuyV2Destination.wholesale);
    session.addProduct(wholesale.id);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final instructions = find.byKey(
      const ValueKey('buy-cart-delivery-instructions-delivery'),
    );
    await showInMainCartList(tester, instructions);

    expect(find.text('Delivery instructions · optional'), findsOneWidget);
    expect(find.text('Shop delivery'), findsNothing);
    expect(find.byKey(const ValueKey('buy-cart-tip-wholesale')), findsNothing);

    final bill = find.byKey(const ValueKey('buy-cart-bill-summary'));
    await showInMainCartList(tester, bill);
    expect(bill, findsOneWidget);
    expect(
      find.descendant(of: bill, matching: find.text('Wholesale packs')),
      findsOneWidget,
    );
    expect(find.text('Bill summary'), findsOneWidget);
    double contentY(Finder target) =>
        tester.getTopLeft(target).dy +
        tester
            .state<ScrollableState>(
              find
                  .byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        axisDirectionToAxis(widget.axisDirection) ==
                            Axis.vertical,
                  )
                  .first,
            )
            .position
            .pixels;
    final billY = contentY(bill);
    final discovery = find.byKey(const PageStorageKey('buy-cart-discovery'));
    await showInMainCartList(tester, discovery);
    expect(contentY(discovery), greaterThan(billY));
    final recommendations = find.byKey(
      const ValueKey('buy-cart-recommendations-wholesale'),
    );
    expect(recommendations, findsOneWidget);
    final heading = find.descendant(
      of: discovery,
      matching: find.text('Explore products'),
    );
    final total = session.scopedPayableTotal;
    final originalQuantity = session.quantityFor(wholesale.id);
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(recommendations, findsNothing);
    expect(session.scopedPayableTotal, total);
    await tester.tap(heading);
    await tester.pumpAndSettle();
    await showInMainCartList(tester, recommendations);
    expect(recommendations, findsOneWidget);
    expect(
      find.descendant(of: recommendations, matching: find.byType(BuyV2AddFace)),
      findsWidgets,
    );
    expect(session.scopedPayableTotal, total);
    final addition = session
        .cartRecommendationsFor(
          BuyV2Destination.wholesale,
          purchaseType: 'wholesale',
        )
        .first;
    expect(session.quantityFor(addition.id), 0);
    final add = find.byKey(ValueKey('buy-cart-add-${addition.id}'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(add.hitTestable(), findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor(addition.id), addition.minimumOrder);
    expect(session.quantityFor(wholesale.id), originalQuantity);
    expect(session.view, BuyV2View.cart);
    expect(
      session.cartLines.any((line) => line.product.id == addition.id),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saved shelf adds productwise and clears only after confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    final shop = productFor(BuyV2Destination.shop);
    final secondShop = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.shop &&
          candidate.id != shop.id &&
          session.fulfilmentModeFor(candidate) ==
              session.fulfilmentModeFor(shop),
    );
    session.toggleSaved(shop.id);
    session.toggleSaved(secondShop.id);
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-saved-decision-shelf')),
      findsOneWidget,
    );
    expect(find.text('Saved in Shop'), findsOneWidget);
    expect(
      session.visibleSavedProducts.map((item) => item.id),
      containsAll([shop.id, secondShop.id]),
    );
    expect(find.byKey(const ValueKey('buy-saved-add-all')), findsNothing);
    final grid = find.byKey(
      ValueKey(
        'buy-vertical-product-grid-buy-products-shop-${session.selectedCategoryId}-saved',
      ),
    );
    expect(grid, findsOneWidget);
    final scroll = find
        .ancestor(
          of: grid,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    Future<void> reveal(Finder target) async {
      for (
        var attempt = 0;
        attempt < 100 && target.hitTestable().evaluate().isEmpty;
        attempt++
      ) {
        final rect = target.evaluate().isEmpty ? null : tester.getRect(target);
        final delta = rect != null && rect.top < tester.getRect(scroll).top
            ? 120.0
            : -120.0;
        final point =
            const [
              Alignment(-.85, 0),
              Alignment(.85, 0),
              Alignment(-.85, -.5),
              Alignment(.85, -.5),
            ].firstWhere(
              (point) => scroll.hitTestable(at: point).evaluate().isNotEmpty,
            );
        await tester.dragFrom(
          point.withinRect(tester.getRect(scroll)),
          Offset(0, delta),
        );
        await tester.pumpAndSettle();
      }
      expect(
        target.hitTestable(),
        findsOneWidget,
        reason:
            'Target ${target.evaluate().isEmpty ? 'missing' : tester.getRect(target)}; viewport ${tester.getRect(scroll)}',
      );
    }

    expect(
      find.byTooltip('Remove ${shop.customerTitle} from Saved'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(ValueKey('buy-save-${shop.id}'))).height,
      equals(44),
    );
    expect(
      tester.getSize(find.byKey(ValueKey('buy-save-${shop.id}'))).width,
      lessThan(80),
    );
    expect(tester.takeException(), isNull);

    final productAdd = find.byKey(ValueKey('buy-add-${shop.id}'));
    await reveal(productAdd);
    await tester.tap(productAdd);
    await tester.pump();
    expect(session.quantityFor(shop.id), shop.minimumOrder);
    expect(session.isSaved(shop.id), isTrue);

    final secondRemove = find.byKey(ValueKey('buy-save-${secondShop.id}'));
    await reveal(secondRemove);
    await tester.tap(secondRemove);
    await tester.pumpAndSettle();
    expect(session.isSaved(secondShop.id), isFalse);
    expect(session.isSaved(shop.id), isTrue);

    final clearSaved = find.byKey(const ValueKey('buy-saved-clear'));
    await reveal(clearSaved);
    await tester.tap(clearSaved);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-saved-clear-sheet')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Clear Saved in Shop?'), findsOneWidget);
    expect(find.text('Keep saved'), findsWidgets);
    expect(find.text('Clear list'), findsWidgets);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('buy-saved-clear-sheet')))
          .height,
      lessThan(300),
    );
    expect(session.isSaved(shop.id), isTrue);
    await tester.tap(find.byKey(const ValueKey('buy-saved-keep')));
    await tester.pumpAndSettle();
    expect(session.isSaved(shop.id), isTrue);

    await tester.tap(find.byKey(const ValueKey('buy-saved-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-saved-confirm-clear')));
    await tester.pumpAndSettle();

    expect(session.isSaved(shop.id), isFalse);
    expect(session.quantityFor(shop.id), shop.minimumOrder);
    expect(find.text('No saved products yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    for (final offerClass in [
      BuyV2OfferClass.wholesale,
      BuyV2OfferClass.bulk,
    ]) {
      testWidgets('C07 Cart quantity choice confirms $offerClass at $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final source = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.wholesale,
          providerCount: 1,
          includeVariantReviewFixtures: true,
        );
        final templates = BuyV2Catalogue.products
            .where((p) => p.destination == BuyV2Destination.wholesale)
            .length;
        final probeCore = BuySession();
        final probe = BuyV2Session(
          core: probeCore,
          cataloguePageSource: source,
        );
        addTearDown(probe.dispose);
        addTearDown(probeCore.dispose);
        BuyV2Product? suppliedPack;
        for (var offset = 0; offset <= 12; offset++) {
          final id = source.productIdAt(0, templates + offset);
          expect(await probe.openLinkedProduct(id), isTrue);
          final candidate = probe.product(id);
          if (candidate.packTerms?.priceTiers.isNotEmpty == true) {
            suppliedPack = candidate.copyWith(offerClass: offerClass);
            break;
          }
        }
        expect(suppliedPack, isNotNull);
        final product = suppliedPack!;
        var now = DateTime.now();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          commerceAdapter: _QuantityTierCommerce(product),
          reviewDataEnabled: false,
          productFactsAdapter: QualifiedTestProductFacts({product.id}),
          catalogueNow: () => now,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        expect(
          session.addProduct(product.id),
          isTrue,
          reason:
              '${session.notice}; '
              'pack valid=${product.hasValidPackTerms}; '
              'facts=${session.productFactsFor(product).orderabilityLabel}',
        );
        session.openCart();
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        final cue = find.byKey(
          ValueKey('buy-cart-quantity-tier-${product.id}'),
        );
        await showInMainCartList(tester, cue);
        await Scrollable.ensureVisible(tester.element(cue), alignment: .5);
        await tester.pumpAndSettle();
        expect(find.textContaining('3 packs more'), findsOneWidget);
        expect(find.textContaining('Item total ₹1,900'), findsOneWidget);
        expect(session.quantityFor(product.id), 2);
        expect(session.cartTotal, 800);
        expect(tester.takeException(), isNull);
        await tester.tap(cue);
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('buy-quantity-input'));
        expect(input, findsNothing);
        expect(session.quantityFor(product.id), 5);
        expect(session.cartLines.single.product.price, 380);
        expect(session.cartTotal, 1900);
        expect(session.cartLines.single.product.pack, product.pack);
        expect(
          session.cartLines.single.product.quantityStep,
          product.quantityStep,
        );
        await showInMainCartList(tester, cue, scrollDelta: -450);
        expect(find.textContaining('Item total ₹2,880'), findsOneWidget);
        await Scrollable.ensureVisible(tester.element(cue), alignment: .5);
        await tester.pumpAndSettle();
        now = now.add(const Duration(days: 2));
        await tester.tap(cue);
        await tester.pumpAndSettle();
        expect(find.textContaining('Pack prices have expired'), findsOneWidget);
        expect(session.quantityFor(product.id), 5);
        expect(session.cartTotal, 1900);
        expect(input, findsNothing);
        expect(cue, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('R37 Cart sections fit compact Android and iOS-size viewports', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final viewport in const [Size(320, 700), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(viewport);
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        final session = BuyV2Session(core: BuySession());
        final product = productFor(destination);
        session.addProduct(product.id);
        session.openCart(
          scope: switch (destination) {
            BuyV2Destination.shop => BuyV2CartScope.shop,
            BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
            BuyV2Destination.medicine => BuyV2CartScope.medicine,
            BuyV2Destination.orders => BuyV2CartScope.all,
          },
        );
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('${viewport.width}-${destination.name}'),
            child: app(session, textScale: viewport.width == 320 ? 1.4 : 1),
          ),
        );
        await tester.pumpAndSettle();

        for (final target in [
          find.byKey(const ValueKey('buy-cart-benefits')),
          find.byKey(ValueKey('buy-cart-delivery-instructions-delivery')),
          find.byKey(const ValueKey('buy-cart-bill-summary')),
          if (session.scopedCartSavings > 0)
            find.byKey(const ValueKey('buy-cart-savings-summary')),
        ]) {
          await showInMainCartList(tester, target);
          expect(target, findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(
          find.byKey(const ValueKey('buy-cart-action-bar')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets(
    'benefit destination fits compact viewport and enlarged customer text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        session.addProduct(productFor(destination).id);
      }
      session.openCart();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
      await showInMainCartList(tester, coupons);
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final medicineDestination = find.byKey(
        const ValueKey('buy-cart-benefit-destination-medicine'),
      );
      await tester.ensureVisible(medicineDestination);
      await tester.pumpAndSettle();
      await tester.tap(medicineDestination);
      await tester.ensureVisible(
        find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
      );
      await tester.pumpAndSettle();

      final destinationSelector = find.byKey(
        const ValueKey('buy-cart-benefit-destination-selector'),
      );
      final kindSelector = find.byKey(
        const ValueKey('buy-cart-benefit-kind-selector'),
      );
      final empty = find.byKey(
        const ValueKey('buy-cart-paymentOffer-empty-medicine'),
      );
      expect(destinationSelector, findsOneWidget);
      expect(tester.getSize(destinationSelector).height, 44);
      expect(tester.getSize(medicineDestination).height, 44);
      expect(tester.getSize(kindSelector).height, 44);
      expect(tester.getSize(empty).height, lessThanOrEqualTo(100));
      await tester.ensureVisible(empty);
      await tester.pumpAndSettle();
      expect(empty.hitTestable(), findsOneWidget);
      expect(
        find.textContaining('Coupons and payment offers are checked'),
        findsNothing,
      );
      expect(empty, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'validated coupon selects, removes and projects its saving into Checkout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: const _AvailableBenefitsAdapter(),
      );
      final shop = productFor(BuyV2Destination.shop);
      session.addProduct(shop.id);
      final originalTotal = session.cartTotal;
      session.openCart(scope: BuyV2CartScope.shop);
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
      await showInMainCartList(tester, coupons);
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      final select = find.byKey(
        const ValueKey('buy-cart-benefit-select-shop-coupon'),
      );
      await tester.ensureVisible(select);
      await tester.pumpAndSettle();
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(find.text('Applied to Cart total'), findsOneWidget);
      expect(session.cartTotal, originalTotal);
      final bill = find.byKey(const ValueKey('buy-cart-bill-summary'));
      await showInMainCartList(tester, bill);
      expect(
        find.descendant(
          of: bill,
          matching: find.byKey(const ValueKey('buy-cart-savings-summary')),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'You save ${buyV2Money(session.scopedCartSavings + session.scopedCouponSaving)}',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Applied coupon ₹10'), findsOneWidget);
      expect(find.text('Product savings'), findsNothing);
      expect(find.text('Coupon saving'), findsNothing);
      expect(session.scopedPayableTotal, originalTotal - 10);
      await showInMainCartList(
        tester,
        find.byKey(const ValueKey('buy-cart-benefit-remove-shop-coupon')),
        scrollDelta: -250,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('buy-cart-benefit-remove-shop-coupon')),
      );
      await tester.pumpAndSettle();
      expect(
        session.selectedCartBenefit(
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
        ),
        isNull,
      );

      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.ensureVisible(coupons);
      await tester.pumpAndSettle();
      await tester.tap(coupons);
      await tester.pumpAndSettle();
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();
      expect(session.checkoutCouponSaving, greaterThan(0));
      expect(
        session.checkoutPayableTotal,
        originalTotal - session.checkoutCouponSaving,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('live coupon shows eligibility, saving and offline retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = _WidgetLiveBenefitsAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: adapter,
    );
    addTearDown(session.dispose);
    final shop = productFor(BuyV2Destination.shop);
    expect(session.addProduct(shop.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);

    await tester.pumpWidget(app(session, textScale: 2));
    await tester.pump();
    final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
    // Loading now starts when the default-open section is built; do not
    // wait for an indeterminate progress animation to settle.
    await tester.scrollUntilVisible(
      coupons,
      250,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsOneWidget,
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-loading')),
      findsOneWidget,
    );

    final evaluatedAt = DateTime.utc(2026, 8, 29, 12);
    adapter.complete(
      BuyV2CartBenefitsSnapshot(
        state: BuyV2CartBenefitsLoadState.ready,
        evaluatedAt: evaluatedAt,
        benefits: [
          BuyV2CartBenefit(
            id: 'live-retailer-sale',
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.shop,
            title: 'Fresh basket sale',
            detail: 'Eligible for the current basket.',
            sourceId: 'retailer-live-source',
            strategy: BuyV2CartBenefitStrategy.timedSale,
            sponsor: BuyV2CartBenefitSponsor.retailer,
            sponsorName: 'Shree Balaji Fresh',
            savingAmount: 10,
            validUntil: evaluatedAt.add(const Duration(hours: 4)),
          ),
          BuyV2CartBenefit(
            id: 'live-spend-opportunity',
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.shop,
            title: 'Selected product saving',
            detail: 'Only these exact products qualify.',
            sourceId: 'provider-published-scope',
            savingAmount: 10,
            minimumSpend: session.scopedCartTotal + 20,
            scope: BuyV2CartBenefitScope.platform,
            validUntil: evaluatedAt.add(const Duration(hours: 4)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final opportunity = find.byKey(
      const ValueKey('buy-cart-offer-opportunity'),
    );
    await showInMainCartList(tester, opportunity);
    expect(opportunity, findsOneWidget);
    expect(find.text('Add ₹20 more to qualify'), findsOneWidget);
    await tester.ensureVisible(opportunity);
    await tester.pumpAndSettle();
    await tester.tap(opportunity);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Only these exact products qualify.'),
      findsOneWidget,
    );
    expect(session.scopedCouponSaving, 0);
    expect(tester.takeException(), isNull);
    await showInMainCartList(
      tester,
      find.byKey(
        const PageStorageKey('buy-cart-benefit-details-live-retailer-sale'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const PageStorageKey('buy-cart-benefit-details-live-retailer-sale'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Time-bound sale · Retailer · Shree Balaji Fresh'),
      findsOneWidget,
    );
    expect(find.textContaining('Save ₹10 now'), findsOneWidget);
    final selectLive = find.byKey(
      const ValueKey('buy-cart-benefit-select-live-retailer-sale'),
    );
    await Scrollable.ensureVisible(tester.element(selectLive), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(selectLive);
    await tester.pumpAndSettle();
    expect(find.text('Applied to Cart total'), findsOneWidget);
    expect(session.scopedCouponSaving, 10);
    expect(
      find.byKey(const ValueKey('buy-cart-offer-opportunity')),
      findsNothing,
    );

    adapter.begin();
    unawaited(session.refreshCartBenefits());
    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-loading')),
      findsOneWidget,
    );
    adapter.complete(
      BuyV2CartBenefitsSnapshot(
        state: BuyV2CartBenefitsLoadState.offline,
        evaluatedAt: evaluatedAt,
        customerMessage: 'Reconnect to check current eligibility.',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-offline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-retry')),
      findsOneWidget,
    );
    expect(session.scopedCouponSaving, 0);
    expect(tester.takeException(), isNull);
  });
}

// Payable display only; connected tests retain real quote/arithmetic coverage.
Widget _r66CartCaptureBoundary(Widget child) =>
    const bool.fromEnvironment('BUY_R66_MAIN_CART_CAPTURE')
    ? RepaintBoundary(
        key: const ValueKey('r66-main-cart-capture'),
        child: child,
      )
    : child;

Future<void> _captureR66MainCart(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R66_MAIN_CART_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-main-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory(
      const String.fromEnvironment(
        'BUY_R66_MAIN_CART_DIRECTORY',
        defaultValue: 'build/r66-cart-wording-review-v3-20260905',
      ),
    );
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Main Cart capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) throw StateError('Main Cart capture encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _QuantityTierCommerce extends Fake implements BuyV2CommerceAdapter {
  _QuantityTierCommerce(this.product);
  final BuyV2Product product;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [product],
    paymentMethods: const {'UPI'},
    businessVerified: true,
    businessVerificationState: BuyV2BusinessVerificationState.verified,
  );
}

class _R66PayableDisplayFixture extends BuyV2Session {
  _R66PayableDisplayFixture(this.displayTotal) : super(core: BuySession());
  int displayTotal;

  void setDisplayTotal(int total) {
    displayTotal = total;
    notifyListeners();
  }

  @override
  int get scopedPayableTotal => displayTotal;

  @override
  int get cartTotal => displayTotal;
}

class _WidgetLiveBenefitsAdapter implements BuyV2LiveCartBenefitsAdapter {
  Completer<BuyV2CartBenefitsSnapshot> _pending = Completer();

  void begin() => _pending = Completer();

  void complete(BuyV2CartBenefitsSnapshot snapshot) {
    if (!_pending.isCompleted) _pending.complete(snapshot);
  }

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => const [];

  @override
  Future<BuyV2CartBenefitsSnapshot> loadEligibility(
    BuyV2CartBenefitsRequest request,
  ) => _pending.future;
}

class _AvailableBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  const _AvailableBenefitsAdapter();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) {
    if (!destinations.contains(BuyV2Destination.shop)) return const [];
    return [
      if (kind == BuyV2CartBenefitKind.coupon)
        const BuyV2CartBenefit(
          id: 'shop-coupon',
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
          title: 'Provider coupon',
          detail: 'Eligibility returned by the test provider.',
          sourceId: 'test-coupon-source',
          sponsor: BuyV2CartBenefitSponsor.retailer,
          sponsorName: 'Retail partner',
          savingAmount: 10,
        ),
      if (kind == BuyV2CartBenefitKind.paymentOffer)
        const BuyV2CartBenefit(
          id: 'shop-payment',
          kind: BuyV2CartBenefitKind.paymentOffer,
          destination: BuyV2Destination.shop,
          title: 'Provider payment offer',
          detail: 'Compatibility returned by the test provider.',
          sourceId: 'test-payment-source',
        ),
    ];
  }
}

class _CartDiscoveryPagingSource extends BuyV2DevelopmentCatalogueSource {
  _CartDiscoveryPagingSource()
    : super(
        destination: BuyV2Destination.shop,
        providerCount: 11,
        skusPerStore: 5000,
      );
  int requests = 0;
  bool failNext = false;
  Future<void>? holdNext;
  BuyV2CatalogueQuery? lastQuery;
  int? lastTotal;
  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    requests++;
    lastQuery = query;
    if (failNext) {
      failNext = false;
      throw StateError('Catalogue test failure');
    }
    final hold = holdNext;
    holdNext = null;
    if (hold != null) {
      await hold;
    }
    final page = await super.loadProducts(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    lastTotal = page.totalCount;
    return page;
  }
}
