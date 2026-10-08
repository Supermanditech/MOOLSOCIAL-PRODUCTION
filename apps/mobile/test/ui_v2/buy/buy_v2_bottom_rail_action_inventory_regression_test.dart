import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('T14 app hot reload retains mounted Cart and Product', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final core = BuySession();
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        buySession: core,
        uiReviewOnly: true,
        initialLocation: '/app/buy?sub=shop',
      ),
    );
    await tester.pumpAndSettle();
    final screen = find.byType(BuyV2Screen);
    final session = tester.widget<BuyV2Screen>(screen).session;
    final state = tester.state(screen);
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    final total = session.cartTotal;
    // Exercise the app's debug lifecycle without waiting for an engine frame.
    // ignore: invalid_use_of_protected_member
    tester.state(find.byType(MoolSocialApp)).reassemble();
    await tester.pumpAndSettle();
    expect(tester.state(screen), same(state));
    expect(tester.widget<BuyV2Screen>(screen).session, same(session));
    expect(session.view, BuyV2View.cart);
    expect(session.cartTotal, total);
    expect(session.openProduct('s-tomato'), isTrue);
    await tester.pumpAndSettle();
    // ignore: invalid_use_of_protected_member
    tester.state(find.byType(MoolSocialApp)).reassemble();
    await tester.pumpAndSettle();
    expect(tester.state(screen), same(state));
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 's-tomato');
    expect(session.cartTotal, total);
    GoRouter.of(tester.element(screen)).go('/app/buy?sub=wholesale');
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.catalogue);
    expect(session.cartTotal, total);
    await tester.pumpWidget(const SizedBox.shrink());
    journey.dispose();
    core.dispose();
    expect(tester.takeException(), isNull);
  });

  Widget app(
    BuyV2Session session, {
    bool offers = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.cartScope,
      initialOffersActive: offers,
    ),
  );

  for (final cartOrigin in [true, false]) {
    testWidgets(
      'T14 Android Product Back retains Offers or Cart origin $cartOrigin',
      (tester) async {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.addProduct('s-tomato');
        if (cartOrigin) session.openCart();
        await tester.pumpWidget(app(session, offers: true));
        await tester.pumpAndSettle();
        final total = session.cartTotal;
        expect(session.openProduct('s-onion'), isTrue);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        if (cartOrigin) expect(session.productReturnLabel, 'Cart');
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          expect(
            tester
                .getSemantics(
                  find.byKey(const ValueKey('buy-compact-cart-indicator')),
                )
                .flagsCollection
                .isSelected,
            cartOrigin ? Tristate.isTrue : Tristate.isFalse,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            session.view,
            cartOrigin ? BuyV2View.cart : BuyV2View.catalogue,
          );
          if (!cartOrigin) {
            expect(
              find.byKey(const ValueKey('buy-local-tab-offers')),
              findsOneWidget,
            );
          }
          expect(session.quantityFor('s-tomato'), 1);
          expect(session.cartTotal, total);
          if (cartOrigin) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(session.quantityFor('s-tomato'), 1);
            expect(session.cartTotal, total);
          }
          expect(
            tester
                .getSemantics(
                  find.byKey(const ValueKey('buy-local-tab-offers')),
                )
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  void expectGlobalActions() {
    expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-buy')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);
  }

  void expectBuyActions() {
    expectGlobalActions();
    final rail = find.byKey(
      const ValueKey('buy-local-navigation-scroll-region'),
    );
    if (rail.evaluate().isNotEmpty) {
      expect(
        find.descendant(of: rail, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      expect(
        find.descendant(of: rail, matching: find.byType(RawScrollbar)),
        findsNothing,
      );
    }
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );
    for (final key in const [
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(
      find.byKey(const ValueKey('buy-scoped-purchase-owner')),
      findsNothing,
    );
  }

  void expectCareActions() {
    expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-book')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    for (final key in const [
      'care-local-tab-doctor',
      'care-local-tab-medicine',
      'care-local-tab-salon',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('Cart rail remains scrollable without blue line $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.addProduct('s-tomato');
      session.openCart();
      await tester.pumpWidget(
        app(session, size: const Size(320, 800), textScale: scale),
      );
      await tester.pumpAndSettle();
      final rail = find.byKey(
        const ValueKey('buy-local-navigation-scroll-region'),
      );
      expect(rail, findsOneWidget);
      expectBuyActions();
      final lane = find.byKey(
        const PageStorageKey('buy-compact-cart-local-navigation-scroll'),
      );
      final total = session.cartTotal;
      await tester.drag(lane, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-local-tab-offers')).hitTestable(),
        findsOneWidget,
      );
      expect(session.cartTotal, total);
      expect(session.view, BuyV2View.cart);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Buy actions remain mounted through every purchase surface', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expectBuyActions();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expectBuyActions();

    expect(session.openProduct('w-onion'), isTrue);
    await tester.pumpAndSettle();
    expectBuyActions();

    expect(session.addProduct('w-onion'), isTrue);
    session.openCart();
    await tester.pumpAndSettle();
    expectBuyActions();

    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectBuyActions();

    session.openOrders();
    await tester.pumpAndSettle();
    expectBuyActions();
    final semantics = tester.ensureSemantics();
    final profile = find.byKey(const ValueKey('buy-open-account'));
    expect(
      tester.getSemantics(profile).getSemanticsData().tooltip,
      'Open your MoolSocial profile',
    );
    expect(
      tester.getSemantics(profile),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    final total = session.cartTotal;
    final quantity = session.quantityFor('w-onion');
    await tester.tap(profile);
    await tester.pumpAndSettle();
    final closeProfile = find.byKey(const Key('global-profile-close'));
    expect(closeProfile, findsOneWidget);
    await tester.tap(closeProfile);
    await tester.pumpAndSettle();
    expect(closeProfile, findsNothing);
    expect(session.cartTotal, total);
    expect(session.quantityFor('w-onion'), quantity);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offers and GST overlay do not remove the established rail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final offersSession = BuyV2Session(core: BuySession());
    addTearDown(offersSession.dispose);

    await tester.pumpWidget(app(offersSession, offers: true));
    await tester.pumpAndSettle();
    expectBuyActions();

    final checkout = BuyV2Session(core: BuySession());
    addTearDown(checkout.dispose);
    expect(checkout.addProduct('w-onion'), isTrue);
    checkout.openCart();
    expect(checkout.openCheckout(), isTrue);
    await tester.pumpWidget(app(checkout));
    await tester.pumpAndSettle();
    expectBuyActions();

    // Invoice editing is already available in unified Checkout. Opening it
    // must not trigger the Place order action merely to reach a former step.
    expect(checkout.checkoutStep, BuyV2CheckoutStep.address);
    final total = checkout.cartTotal;
    final quantity = checkout.quantityFor('w-onion');
    expect(checkout.checkoutPaymentAttempt, isNull);
    final change = find.byKey(const ValueKey('buy-invoice-change'));
    await tester.ensureVisible(change);
    await tester.pumpAndSettle();
    await tester.tap(change);
    await tester.pumpAndSettle();
    expect(find.text('Invoice recipient'), findsOneWidget);
    expectBuyActions();
    final add = find.byKey(const ValueKey('buy-invoice-add-business'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-gst-invoice-sheet')), findsOneWidget);
    expect(checkout.view, BuyV2View.account);
    expectBuyActions();
    await tester.tap(find.byKey(const ValueKey('buy-invoice-close')));
    await tester.pumpAndSettle();
    expect(checkout.view, BuyV2View.checkout);
    expectBuyActions();
    expect(checkout.cartTotal, total);
    expect(checkout.quantityFor('w-onion'), quantity);
    expect(checkout.checkoutSubmissionState, BuyV2CheckoutSubmissionState.idle);
    expect(checkout.checkoutPaymentAttempt, isNull);
    expect(checkout.confirmedOrders, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medicine Cart and Checkout retain every Care action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.medicine);

    await tester.pumpWidget(
      app(session, size: const Size(320, 568), textScale: 1.4),
    );
    await tester.pumpAndSettle();
    expectCareActions();

    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectCareActions();
    expect(tester.takeException(), isNull);
  });
}
