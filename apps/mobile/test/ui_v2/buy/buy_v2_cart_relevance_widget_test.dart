import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session, {double textScale = 1}) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
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
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
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

      await tester.tap(find.byKey(const ValueKey('buy-saved-clear')));
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
      expect(find.text('No Saved products here'), findsOneWidget);
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
    'validated coupon selects, removes and projects into Checkout without changing total',
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
      expect(find.text('Selected for Checkout review'), findsOneWidget);
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

      final checkoutBenefit = find.byKey(
        const ValueKey('buy-checkout-benefit-shop-coupon'),
      );
      await tester.scrollUntilVisible(
        checkoutBenefit,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      await tester.pumpAndSettle();
      expect(checkoutBenefit, findsOneWidget);
      expect(
        find.textContaining('No amount has been deducted'),
        findsOneWidget,
      );
      expect(session.checkoutPayableTotal, originalTotal);
      expect(tester.takeException(), isNull);
    },
  );
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
