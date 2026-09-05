import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

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

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == destination &&
            !candidate.requiresPrescription,
      );

  Future<void> showInMainCartList(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      450,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
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
            final review = find.widgetWithText(FilledButton, 'Review order');
            expect(tester.getSize(review).height, greaterThanOrEqualTo(44));
            final label = find.descendant(
              of: review,
              matching: find.text('Review order'),
            );
            expect(
              tester.getSize(review).height,
              greaterThanOrEqualTo(tester.getSize(label).height),
            );
            expect(tester.getBottomRight(review).dy, lessThanOrEqualTo(800));
            final allScope = find.byKey(
              const ValueKey('buy-cart-scope-value-motion-all'),
            );
            final allValue = tester.widget<BuyV2FiniteValueTransition>(
              allScope,
            );
            expect(allValue.text, buyV2Money(total));
            final allSize = buyV2ValueTextSize(
              tester.element(allScope),
              allValue.text,
              allValue.style,
            );
            expect(
              tester.getSize(allScope).width,
              greaterThanOrEqualTo(allSize.width),
            );
            expect(
              tester.getSize(allScope).height,
              greaterThanOrEqualTo(allSize.height),
            );
            for (final scope in ['all', 'shop', 'wholesale']) {
              final control = find.byKey(ValueKey('buy-cart-scope-$scope'));
              expect(tester.getRect(control).left, greaterThanOrEqualTo(0));
              expect(tester.getRect(control).right, lessThanOrEqualTo(width));
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
      for (final key in [
        'buy-cart-header-value-motion',
        'buy-cart-scope-value-motion-all',
        'buy-cart-scope-value-motion-shop',
        'buy-cart-scope-value-motion-wholesale',
        'buy-cart-benefit-entry-Coupons-motion',
        'buy-cart-benefit-entry-Payment offers-motion',
      ]) {
        final finder = find.byKey(ValueKey(key));
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
          expect(find.textContaining('MOQ 1 pack ·'), findsOneWidget);
          expect(find.textContaining('MOQ 1 packs'), findsNothing);
        }
        final owner = find.byKey(
          ValueKey('buy-cart-delivery-instructions-${destination.name}'),
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
            ValueKey('buy-cart-instruction-${destination.name}-${option.id}'),
          );
          await tester.scrollUntilVisible(
            action,
            110,
            scrollable: lane,
            maxScrolls: 15,
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
    expect(find.byTooltip('Empty cart'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);

    for (final product in products) {
      final packshot = find.byKey(ValueKey('buy-cart-packshot-${product.id}'));
      await showInMainCartList(tester, packshot);
      expect(packshot, findsOneWidget);
    }
    expect(find.text('Shop order'), findsNothing);
    expect(find.text('Wholesale order'), findsNothing);
    expect(find.text('Medicine order'), findsNothing);

    final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
    await showInMainCartList(tester, coupons);
    expect(coupons, findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-cart-payment-offers')),
      findsOneWidget,
    );
    expect(find.textContaining('Tip Shop delivery partner'), findsNothing);
    expect(find.textContaining('Tip pharmacy delivery partner'), findsNothing);

    await tester.tap(coupons);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-page')),
      findsOneWidget,
    );
    expect(find.textContaining('Shop ·'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-cart-coupon-empty-shop')),
      findsOneWidget,
    );
    expect(find.text('No Shop coupons right now'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-paymentOffer-empty-shop')),
      findsOneWidget,
    );
    expect(find.text('No Shop payment offers right now'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-destination-wholesale')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Wholesale ·'), findsOneWidget);
    expect(find.text('No trade payment offers right now'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-destination-medicine')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Medicine ·'), findsOneWidget);
    expect(find.text('No Medicine payment offers right now'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-cart-benefits-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-cart-benefits-page')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-cart-payment-offers')),
      findsOneWidget,
    );
  });

  testWidgets(
    'device-review offer UI selects and removes all six seeded states',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
      );
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        session.addProduct(productFor(destination).id);
      }
      final originalTotal = session.cartTotal;
      session.openCart();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
      await showInMainCartList(tester, coupons);
      await tester.tap(coupons);
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        await tester.tap(
          find.byKey(
            ValueKey('buy-cart-benefit-destination-${destination.name}'),
          ),
        );
        await tester.pumpAndSettle();
        for (final kind in BuyV2CartBenefitKind.values) {
          await tester.tap(
            find.byKey(
              ValueKey(
                'buy-cart-benefit-kind-'
                '${kind == BuyV2CartBenefitKind.coupon ? 'coupon' : 'payment'}',
              ),
            ),
          );
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
          expect(tester.getSize(card).height, lessThan(150));
          final select = find.byKey(
            ValueKey('buy-cart-benefit-select-$benefitId'),
          );
          await tester.ensureVisible(select);
          await tester.pumpAndSettle();
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
      const ValueKey('buy-cart-delivery-instructions-wholesale'),
    );
    await showInMainCartList(tester, instructions);

    expect(find.text('Trade receiving'), findsOneWidget);
    expect(find.text('Shop delivery'), findsNothing);
    expect(find.byKey(const ValueKey('buy-cart-tip-wholesale')), findsNothing);

    final bill = find.byKey(const ValueKey('buy-cart-bill-summary'));
    await showInMainCartList(tester, bill);
    expect(bill, findsOneWidget);
    expect(find.text('Wholesale trade packs'), findsOneWidget);
    expect(find.text('Bill summary'), findsOneWidget);
  });

  testWidgets(
    'Saved shelf adds productwise and clears only after confirmation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      final shop = productFor(BuyV2Destination.shop);
      final secondShop = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.shop &&
            candidate.id != shop.id,
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
      expect(find.byKey(const ValueKey('buy-saved-add-all')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
        findsNothing,
      );
      expect(find.text('Remove'), findsWidgets);
      expect(
        tester.getSize(find.byKey(ValueKey('buy-save-${shop.id}'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(find.byKey(ValueKey('buy-save-${shop.id}'))).width,
        lessThan(80),
      );
      expect(tester.takeException(), isNull);

      final productAdd = find.byKey(ValueKey('buy-add-${shop.id}'));
      await tester.ensureVisible(productAdd);
      await tester.pumpAndSettle();
      await tester.tap(productAdd);
      await tester.pump();
      expect(session.quantityFor(shop.id), shop.minimumOrder);
      expect(session.isSaved(shop.id), isTrue);

      final secondRemove = find.byKey(ValueKey('buy-save-${secondShop.id}'));
      await tester.ensureVisible(secondRemove);
      await tester.pumpAndSettle();
      await tester.tap(secondRemove);
      await tester.pumpAndSettle();
      expect(session.isSaved(secondShop.id), isFalse);
      expect(session.isSaved(shop.id), isTrue);

      final clearSaved = find.byKey(const ValueKey('buy-saved-clear'));
      await tester.ensureVisible(clearSaved);
      await tester.pumpAndSettle();
      await tester.tap(clearSaved);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-saved-clear-sheet')),
        findsOneWidget,
      );
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
    },
  );

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
          find.byKey(
            ValueKey('buy-cart-delivery-instructions-${destination.name}'),
          ),
          find.byKey(const ValueKey('buy-cart-bill-summary')),
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
      await tester.tap(coupons);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-cart-benefits-page')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final medicineDestination = find.byKey(
        const ValueKey('buy-cart-benefit-destination-medicine'),
      );
      await tester.ensureVisible(medicineDestination);
      await tester.pumpAndSettle();
      await tester.tap(medicineDestination);
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
      expect(tester.getTopLeft(empty).dy, lessThanOrEqualTo(220));
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
      await tester.tap(coupons);
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
      await tester.tap(find.byKey(const ValueKey('buy-cart-benefits-back')));
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

    await tester.pumpWidget(app(session));
    await tester.pump();
    final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
    await showInMainCartList(tester, coupons);
    await tester.tap(coupons);
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
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Time-bound sale · Retailer · Shree Balaji Fresh'),
      findsOneWidget,
    );
    expect(find.textContaining('Save ₹10 now'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-select-live-retailer-sale')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Applied to Cart total'), findsOneWidget);
    expect(session.scopedCouponSaving, 10);

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
    final directory = Directory('build/r66-cart-wording-review-v3-20260905');
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

class _R66PayableDisplayFixture extends BuyV2Session {
  _R66PayableDisplayFixture(this.displayTotal) : super(core: BuySession());
  final int displayTotal;

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
