import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
