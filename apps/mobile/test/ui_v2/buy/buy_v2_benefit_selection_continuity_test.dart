import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('R669 coupon minimum uses its own destination subtotal', () {
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    session.addProduct('s-tomato');
    expect(session.setCartQuantity('s-tomato', '12'), isTrue);
    expect(session.totalForDestination(BuyV2Destination.shop), 444);
    session.addProduct('w-notebook');
    expect(
      session.cartBenefits(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
      ),
      isEmpty,
    );
    expect(
      session
          .cartBenefits(kind: BuyV2CartBenefitKind.coupon)
          .every(
            (benefit) => benefit.destination == BuyV2Destination.wholesale,
          ),
      isTrue,
    );
  });

  test('R669 coupon revoked below minimum cannot silently return', () {
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    session.addProduct('s-tomato');
    expect(session.setCartQuantity('s-tomato', '14'), isTrue);
    final coupon = session
        .cartBenefits(
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
        )
        .first;
    expect(session.chooseCartBenefit(coupon), isTrue);
    expect(session.setCartQuantity('s-tomato', '12'), isTrue);
    expect(
      session.selectedCartBenefit(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
      ),
      isNull,
    );
    expect(session.chooseCartBenefit(coupon), isFalse);
    expect(session.setCartQuantity('s-tomato', '14'), isTrue);
    expect(
      session.selectedCartBenefit(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
      ),
      isNull,
    );
    expect(session.chooseCartBenefit(coupon), isTrue);
  });

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: r66VisualCaptureRoot(child!),
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

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 coupon below minimum is unavailable at $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      expect(session.setCartQuantity('s-tomato', '12'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      await tester.pumpWidget(
        app(session, textScale: scale, reducedMotion: true),
      );
      await tester.pumpAndSettle();
      final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
      await tester.scrollUntilVisible(
        coupons,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(session.scopedPayableTotal, 444);
      expect(session.scopedCouponSaving, 0);
      expect(
        find.byKey(const ValueKey('buy-cart-benefit-select-shop-coupon')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await captureR66Visual(tester, 'r669-coupon-below-minimum-$scale');
      await tester.ensureVisible(coupons);
      await tester.pumpAndSettle();
      await tester.tap(coupons);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.scopedPayableTotal, 444);
      expect(tester.takeException(), isNull);
      await captureR66Visual(tester, 'r669-coupon-cart-return-$scale');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('R66 027 payment offer explains unchanged payable at $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('w-notebook');
      session.chooseCartBenefit(
        session
            .cartBenefits(
              kind: BuyV2CartBenefitKind.coupon,
              destination: BuyV2Destination.wholesale,
            )
            .last,
      );
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.scopedCartTotal, 3480);
      expect(session.scopedCouponSaving, 300);
      expect(session.scopedPayableTotal, 3180);
      await tester.pumpWidget(
        app(session, textScale: scale, reducedMotion: true),
      );
      await tester.pumpAndSettle();
      final entry = find.byKey(const ValueKey('buy-cart-coupons'));
      await tester.scrollUntilVisible(
        entry,
        420,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await Scrollable.ensureVisible(tester.element(entry), alignment: .3);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      final paymentKind = find.byKey(
        const ValueKey('buy-cart-benefit-kind-payment'),
      );
      await tester.ensureVisible(paymentKind);
      await tester.pumpAndSettle();
      await tester.tap(paymentKind);
      await tester.pumpAndSettle();
      final select = find.byKey(
        const ValueKey('buy-cart-benefit-select-wholesale-paymentOffer-3'),
      );
      await tester.scrollUntilVisible(
        select,
        180,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.ensureVisible(select);
      await tester.pumpAndSettle();
      expect(select.hitTestable(), findsOneWidget);
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(find.textContaining('Potential saving ₹300'), findsOneWidget);
      expect(find.textContaining('Not eligible with PhonePe'), findsOneWidget);
      final collapse = find.byKey(const ValueKey('buy-cart-coupons'));
      await tester.ensureVisible(collapse);
      await tester.pumpAndSettle();
      await tester.tap(collapse);
      await tester.pumpAndSettle();
      final status = find.byKey(
        const ValueKey(
          'buy-cart-payment-offer-status-wholesale-paymentOffer-3',
        ),
      );
      await tester.ensureVisible(status);
      await tester.pumpAndSettle();
      expect(find.textContaining('Not eligible with PhonePe'), findsOneWidget);
      expect(
        find.textContaining('Payment savings are not included in this total.'),
        findsOneWidget,
      );
      for (final element
          in find
              .descendant(of: status, matching: find.byType(RichText))
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
      expect(session.scopedPayableTotal, 3180);
      await tester.tap(find.widgetWithText(FilledButton, 'Checkout'));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.checkout);
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-address')),
      );
      await tester.pumpAndSettle();
      expect(session.checkoutStep, BuyV2CheckoutStep.payment);
      final pine = find.byKey(const ValueKey('buy-payment-Pine Labs'));
      await Scrollable.ensureVisible(tester.element(pine), alignment: .3);
      await tester.pumpAndSettle();
      expect(pine.hitTestable(), findsOneWidget);
      await tester.tap(pine);
      await tester.pumpAndSettle();
      expect(session.selectedPayment, 'Pine Labs');
      expect(session.checkoutAmountDueNow, 3180);
      final summary = find.byKey(
        const ValueKey('buy-checkout-payment-summary'),
      );
      await tester.ensureVisible(summary);
      await tester.pumpAndSettle();
      expect(find.textContaining('Pending confirmation'), findsOneWidget);
      expect(
        find.textContaining('Payment savings are not included in this total.'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: summary, matching: find.text('₹3,180')),
        findsOneWidget,
      );
      for (final element
          in find
              .descendant(of: summary, matching: find.byType(RichText))
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
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-payment')),
      );
      await tester.pumpAndSettle();
      final confirmation = find.byKey(
        const ValueKey('buy-checkout-confirm-benefits'),
      );
      await tester.ensureVisible(confirmation);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Coupon saving −₹300 included'),
        findsOneWidget,
      );
      expect(find.textContaining('Pending confirmation'), findsOneWidget);
      expect(session.checkoutAmountDueNow, 3180);
      await captureR66Visual(tester, '027-final-benefits-text-$scale');
      for (final element
          in find
              .descendant(of: confirmation, matching: find.byType(RichText))
              .evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final terms in [
    (
      spend: 4000,
      quantity: null,
      start: null,
      end: null,
      reason: 'Minimum Wholesale product subtotal ₹4,000',
    ),
    (
      spend: null,
      quantity: 2,
      start: null,
      end: null,
      reason: 'Minimum 2 packs in Wholesale',
    ),
    (
      spend: null,
      quantity: null,
      start: DateTime(2100),
      end: null,
      reason: 'This offer has not started',
    ),
    (
      spend: null,
      quantity: null,
      start: null,
      end: DateTime(2000),
      reason: 'This offer has expired',
    ),
  ]) {
    testWidgets('R66 027 published payment condition ${terms.reason}', (
      tester,
    ) async {
      final offer = BuyV2CartBenefit(
        id: 'terms-offer',
        kind: BuyV2CartBenefitKind.paymentOffer,
        destination: BuyV2Destination.wholesale,
        title: 'Payment offer',
        detail: 'Review the current payment terms.',
        sourceId: 'terms-source',
        savingAmount: 300,
        minimumSpend: terms.spend,
        minimumQuantity: terms.quantity,
        validFrom: terms.start,
        validUntil: terms.end,
      );
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        cartBenefitsAdapter: _PaymentStatusAdapter(offer),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('w-notebook');
      expect(session.chooseCartBenefit(offer), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final collapse = find.byKey(const ValueKey('buy-cart-coupons'));
      await tester.scrollUntilVisible(
        collapse,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(collapse);
      await tester.pumpAndSettle();
      final status = find.byKey(
        const ValueKey('buy-cart-payment-offer-status-terms-offer'),
      );
      await tester.scrollUntilVisible(
        status,
        420,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(terms.reason), findsOneWidget);
      expect(
        find.textContaining('Payment savings are not included in this total.'),
        findsOneWidget,
      );
      expect(session.scopedPayableTotal, 3480);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  Future<void> openBenefitsPage(
    WidgetTester tester,
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      app(session, textScale: textScale, reducedMotion: reducedMotion),
    );
    await tester.pumpAndSettle();
    final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
    await tester.scrollUntilVisible(
      coupons,
      420,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsOneWidget,
    );
  }

  testWidgets(
    'validated coupon and payment selections continue to exact Cart review',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
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
      // This selection journey requires a Shop basket meeting the coupon's
      // published minimum; an unrelated Wholesale basket cannot qualify it.
      expect(
        session.setCartQuantity(productFor(BuyV2Destination.shop).id, '20'),
        isTrue,
      );
      session.openCart(scope: BuyV2CartScope.all);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
      await tester.scrollUntilVisible(
        coupons,
        420,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      final beforeScroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      expect(find.text('Return to Cart'), findsNothing);
      expect(session.view, BuyV2View.cart);
      final shopCoupon = find.byKey(
        const ValueKey('buy-cart-benefit-select-shop-coupon'),
      );
      await tester.ensureVisible(shopCoupon);
      await tester.pumpAndSettle();
      await tester.tap(shopCoupon);
      await tester.pumpAndSettle();
      expect(
        session.selectedCartBenefitsFor({BuyV2Destination.shop}),
        hasLength(1),
      );

      final kindControl = find.byKey(
        const ValueKey('buy-cart-benefit-kind-payment'),
      );
      await tester.ensureVisible(kindControl);
      await tester.pumpAndSettle();
      await tester.tap(kindControl);
      await tester.pumpAndSettle();
      final shopPayment = find.byKey(
        const ValueKey('buy-cart-benefit-select-shop-paymentOffer'),
      );
      await tester.ensureVisible(shopPayment);
      await tester.pumpAndSettle();
      await tester.tap(shopPayment);
      await tester.pumpAndSettle();
      expect(
        session.selectedCartBenefitsFor({BuyV2Destination.shop}),
        hasLength(2),
      );

      final collapse = find.byKey(const ValueKey('buy-cart-coupons'));
      await tester.ensureVisible(collapse);
      await tester.pumpAndSettle();
      await tester.tap(collapse);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-cart-benefits-inline')),
        findsNothing,
      );
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.all);
      expect(
        session.selectedCartBenefitsFor({
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        }),
        hasLength(2),
      );
      final afterScroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(afterScroll, greaterThanOrEqualTo(0));
      expect(beforeScroll, greaterThanOrEqualTo(0));
      expect(find.textContaining('2 selected for review'), findsOneWidget);
      expect(find.textContaining('applied'), findsNothing);
      expect(find.textContaining('accepted'), findsNothing);
    },
  );

  // Historical case identities retained in the regression ledger. Completion
  // now means collapsing inline content; no route is pushed or popped.
  testWidgets('completion is one native action and Back remains intact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    session.addProduct(productFor(BuyV2Destination.shop).id);
    session.addProduct(productFor(BuyV2Destination.wholesale).id);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await openBenefitsPage(tester, session);
    final beforeScope = session.cartScope;
    final inline = find.byKey(const ValueKey('buy-cart-benefits-inline'));
    expect(find.byKey(const ValueKey('buy-cart-benefits-page')), findsNothing);
    expect(find.byTooltip('Back to Cart'), findsNothing);
    expect(session.view, BuyV2View.cart);
    final header = find.byKey(const ValueKey('buy-cart-coupons'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(inline, findsNothing);
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, beforeScope);
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(inline, findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('completion stays stable at 320px 140 percent reduced motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    session.addProduct(productFor(BuyV2Destination.medicine).id);
    session.openCart(scope: BuyV2CartScope.medicine);
    final total = session.scopedPayableTotal;
    await openBenefitsPage(
      tester,
      session,
      textScale: 1.4,
      reducedMotion: true,
    );
    final beforeScope = session.cartScope;
    final header = find.byKey(const ValueKey('buy-cart-coupons'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsNothing,
    );
    expect(session.scopedPayableTotal, total);
    expect(session.cartScope, beforeScope);
    expect(find.text('Return to Cart'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline benefits follow basket switching without leaving Cart', (
    tester,
  ) async {
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    session.addProduct('s-tomato');
    session.addProduct('w-notebook');
    session.openCart();
    await openBenefitsPage(tester, session);
    final quantity = session.quantityFor('w-notebook');
    final total = session.cartTotal;
    session.chooseCartScope(BuyV2CartScope.wholesale);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-cart-benefit-select-wholesale-coupon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-cart-benefit-select-shop-coupon')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-cart-benefits-page')), findsNothing);
    expect(session.view, BuyV2View.cart);
    expect(session.quantityFor('w-notebook'), quantity);
    expect(session.cartTotal, total);
    final header = find.byKey(const ValueKey('buy-cart-coupons'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-inline')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('inline coupons swipe and apply in Cart at $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(
        core: BuySession(),
        cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
      );
      session.addProduct('w-notebook');
      session.openCart();
      await openBenefitsPage(tester, session, textScale: scale);
      final carousel = find.byKey(
        const PageStorageKey('buy-cart-benefits-carousel-wholesale-coupon'),
      );
      await tester.ensureVisible(carousel);
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: carousel,
        matching: find.byType(Scrollable),
      );
      await tester.drag(carousel, const Offset(-240, 0));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      final coupon = session
          .cartBenefits(
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.wholesale,
          )
          .last;
      final select = find.byKey(
        ValueKey('buy-cart-benefit-select-${coupon.id}'),
      );
      await tester.ensureVisible(select);
      await tester.pumpAndSettle();
      expect(select.hitTestable(), findsOneWidget);
      final card = find.byKey(ValueKey('buy-cart-benefit-${coupon.id}'));
      final title = find.descendant(
        of: card,
        matching: find.text(coupon.title),
      );
      final titleRect = tester.getRect(title);
      final actionRect = tester.getRect(select);
      expect(actionRect.left, greaterThanOrEqualTo(titleRect.right));
      expect((actionRect.center.dy - titleRect.center.dy).abs(), lessThan(1));
      final initialHeight = tester.getSize(card).height;
      final band = find.byKey(ValueKey('buy-cart-benefit-colour-${coupon.id}'));
      final bandBox = find.descendant(
        of: band,
        matching: find.byType(ColoredBox),
      );
      final colour = tester.widget<ColoredBox>(bandBox).color;
      expect(colour.a, 1);
      final coupons = session.cartBenefits(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.wholesale,
      );
      final colours = [
        for (final item in coupons)
          tester
              .widget<ColoredBox>(
                find.descendant(
                  of: find.byKey(
                    ValueKey('buy-cart-benefit-colour-${item.id}'),
                  ),
                  matching: find.byType(ColoredBox),
                ),
              )
              .color,
      ];
      for (var index = 1; index < colours.length; index++) {
        expect(colours[index], isNot(colours[index - 1]));
      }

      for (final text in tester.widgetList<Text>(
        find.descendant(of: card, matching: find.byType(Text)),
      )) {
        final foreground = text.style?.color;
        if (foreground == null) continue;
        final first = foreground.computeLuminance();
        final second = colour.computeLuminance();
        final contrast = (first > second)
            ? (first + .05) / (second + .05)
            : (second + .05) / (first + .05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: text.data);
      }
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(
        session
            .selectedCartBenefit(
              kind: BuyV2CartBenefitKind.coupon,
              destination: BuyV2Destination.wholesale,
            )
            ?.id,
        coupon.id,
      );
      expect(session.scopedCouponSaving, coupon.savingAmount);
      expect(session.view, BuyV2View.cart);
      expect(
        find.byKey(const ValueKey('buy-cart-benefits-page')),
        findsNothing,
      );
      final remove = find.byKey(
        ValueKey('buy-cart-benefit-remove-${coupon.id}'),
      );
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(tester.getSize(card).height, closeTo(initialHeight, 1));
      expect(tester.widget<ColoredBox>(bandBox).color, colour);
      expect(session.scopedCouponSaving, 0);
      expect(session.quantityFor('w-notebook'), greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}

class _PaymentStatusAdapter extends BuyV2SeededCartBenefitsAdapter {
  const _PaymentStatusAdapter(this.offer);

  final BuyV2CartBenefit offer;

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) =>
      kind == BuyV2CartBenefitKind.paymentOffer &&
          destinations.contains(offer.destination) &&
          itemTotal > 0
      ? [offer]
      : const [];
}
