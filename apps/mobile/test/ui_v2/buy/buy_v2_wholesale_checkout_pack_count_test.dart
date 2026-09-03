import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: safeArea,
        viewPadding: safeArea,
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.checkoutScope,
    ),
  );

  BuyV2Session checkoutSession({
    List<String> productIds = const ['w-onion'],
    BuyV2CartScope scope = BuyV2CartScope.wholesale,
  }) {
    final session = BuyV2Session(core: BuySession());
    for (final productId in productIds) {
      expect(session.addProduct(productId), isTrue, reason: productId);
    }
    session.openCart(scope: scope);
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    expect(session.continueCheckoutFromPayment(), isTrue);
    return session;
  }

  testWidgets('one Wholesale product at MOQ is one product and two packs', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkoutSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(
      buyV2WholesaleCheckoutPackCountContractVersion,
      'buy-wholesale-checkout-pack-count-v1',
    );
    expect(find.text('Delivery 1 · 1 product · 2 packs'), findsOneWidget);
    expect(find.text('1 product · 2 packs'), findsOneWidget);
    expect(find.textContaining('2 products'), findsNothing);
    expect(find.text('Place order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple Wholesale products retain distinct pack total', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkoutSession(productIds: const ['w-onion', 'w-potato']);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Delivery 1 · 2 products · 4 packs'), findsOneWidget);
    expect(find.text('2 products · 4 packs'), findsOneWidget);
    expect(session.checkoutLines, hasLength(2));
    expect(session.checkoutItemCount, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale Checkout excludes Shop quantities from its count', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkoutSession(productIds: const ['s-tomato', 'w-onion']);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(session.checkoutScope, BuyV2CartScope.wholesale);
    expect(session.checkoutLines, hasLength(1));
    expect(find.text('Delivery 1 · 1 product · 2 packs'), findsOneWidget);
    expect(find.text('1 product · 2 packs'), findsOneWidget);
    expect(find.textContaining('3 packs'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-Wholesale Checkout keeps established product wording', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkoutSession(
      productIds: const ['s-tomato'],
      scope: BuyV2CartScope.shop,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Delivery 1 · 1 product'), findsOneWidget);
    expect(find.text('1 product'), findsOneWidget);
    expect(find.textContaining('packs'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all scope uses pack wording when every line is Wholesale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    expect(session.addProduct('w-onion'), isTrue);
    session.openCart();
    expect(session.cartScope, BuyV2CartScope.all);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(
      find.text('1 product · 2 packs · Wholesale · ₹1,550'),
      findsOneWidget,
    );

    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();
    expect(session.continueCheckoutFromAddress(), isTrue);
    expect(session.continueCheckoutFromPayment(), isTrue);
    await tester.pumpAndSettle();
    expect(session.checkoutScope, BuyV2CartScope.all);
    expect(find.text('Delivery 1 · 1 product · 2 packs'), findsOneWidget);
    expect(find.text('1 product · 2 packs'), findsOneWidget);
    expect(find.textContaining('2 products'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed all scope retains generic item wording', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    expect(session.addProduct('s-tomato'), isTrue);
    expect(session.addProduct('w-onion'), isTrue);
    session.openCart();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(
      find.text('2 products · 3 items · Shop + Wholesale · ₹1,587'),
      findsOneWidget,
    );
    expect(find.textContaining('3 packs'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back and compact insets retain exact Wholesale count', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewports = <({Size size, double scale, EdgeInsets safe})>[
      (
        size: const Size(320, 568),
        scale: 1.4,
        safe: const EdgeInsets.symmetric(vertical: 24),
      ),
      (
        size: const Size(430, 932),
        scale: 1.2,
        safe: const EdgeInsets.only(top: 59, bottom: 34),
      ),
    ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;
      final session = checkoutSession();
      await tester.pumpWidget(
        app(
          session,
          size: viewport.size,
          textScale: viewport.scale,
          safeArea: viewport.safe,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delivery 1 · 1 product · 2 packs'), findsOneWidget);
      final actionBar = find.byKey(const ValueKey('buy-checkout-action-bar'));
      expect(actionBar, findsOneWidget);
      expect(
        tester.getBottomRight(actionBar).dy,
        lessThanOrEqualTo(viewport.size.height - viewport.safe.bottom),
      );
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.checkoutStep, BuyV2CheckoutStep.payment);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.checkoutStep, BuyV2CheckoutStep.address);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(session.scopedItemCount, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });
}
