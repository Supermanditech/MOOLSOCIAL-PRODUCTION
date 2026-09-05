import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  for (final scale in [1.0, 2.0]) {
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
      final entry = find.byKey(const ValueKey('buy-cart-payment-offers'));
      await tester.scrollUntilVisible(
        entry,
        420,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await Scrollable.ensureVisible(tester.element(entry), alignment: .3);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      final select = find.byKey(
        const ValueKey('buy-cart-benefit-select-wholesale-paymentOffer-3'),
      );
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(find.textContaining('Potential saving ₹300'), findsOneWidget);
      expect(find.textContaining('Not eligible with PhonePe'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-cart-benefit-completion')),
      );
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
      await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
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
    await tester.tap(coupons);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-cart-benefits-page')),
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
      await tester.tap(coupons);
      await tester.pumpAndSettle();

      expect(find.text('Return to Cart'), findsOneWidget);
      final shopCoupon = find.byKey(
        const ValueKey('buy-cart-benefit-select-shop-coupon'),
      );
      await tester.ensureVisible(shopCoupon);
      await tester.tap(shopCoupon);
      await tester.pumpAndSettle();
      expect(find.text('Review 1 selection in Cart'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
      );
      await tester.pumpAndSettle();
      final shopPayment = find.byKey(
        const ValueKey('buy-cart-benefit-select-shop-paymentOffer'),
      );
      await tester.ensureVisible(shopPayment);
      await tester.tap(shopPayment);
      await tester.pumpAndSettle();
      expect(find.text('Review 2 selections in Cart'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('buy-cart-benefit-completion')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-cart-benefits-page')),
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
      expect(afterScroll, closeTo(beforeScroll, .01));
      expect(find.textContaining('1 selected for review'), findsNWidgets(2));
      expect(find.textContaining('applied'), findsNothing);
      expect(find.textContaining('accepted'), findsNothing);
    },
  );

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

    final completion = find.byKey(
      const ValueKey('buy-cart-benefit-completion'),
    );
    expect(completion, findsOneWidget);
    expect(
      tester
          .getSemantics(completion)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(find.byTooltip('Back to Cart'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Cart'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, beforeScope);
    expect(find.byKey(const ValueKey('buy-cart-benefits-page')), findsNothing);
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
    await openBenefitsPage(
      tester,
      session,
      textScale: 1.4,
      reducedMotion: true,
    );

    final completion = find.byKey(
      const ValueKey('buy-cart-benefit-completion'),
    );
    expect(tester.getSize(completion).height, 44);
    final labelMotion = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('buy-cart-benefit-completion-label-motion')),
    );
    expect(labelMotion.duration, Duration.zero);
    final listener = tester.widget<Listener>(
      find
          .descendant(
            of: find.byKey(const ValueKey('buy-cart-benefit-completion-depth')),
            matching: find.byType(Listener),
          )
          .first,
    );
    expect(listener.onPointerDown, isNull);
    expect(find.text('Return to Cart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
