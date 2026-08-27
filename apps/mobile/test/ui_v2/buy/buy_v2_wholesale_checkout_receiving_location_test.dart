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

  BuyV2Session checkout(List<String> ids, {BuyV2CartScope? scope}) {
    final session = BuyV2Session(core: BuySession());
    for (final id in ids) {
      expect(session.addProduct(id), isTrue, reason: id);
    }
    if (scope == null) {
      session.openCart();
    } else {
      session.openCart(scope: scope);
    }
    expect(session.openCheckout(), isTrue);
    return session;
  }

  testWidgets('Wholesale-only Checkout names the receiving location', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(
      buyV2WholesaleCheckoutReceivingLocationContractVersion,
      'buy-wholesale-checkout-receiving-location-v1',
    );
    expect(find.text('Receiving location · Home'), findsOneWidget);
    expect(find.text('Delivering to Home'), findsNothing);
    expect(find.text('Sardarpura, Jodhpur · 342003'), findsOneWidget);
    final location = find.byKey(
      const ValueKey('buy-wholesale-checkout-receiving-location'),
    );
    expect(location, findsOneWidget);
    expect(
      tester.getSemantics(location).label,
      contains('Receiving location · Home'),
    );
    expect(
      tester.getSemantics(location).label,
      contains('Sardarpura, Jodhpur · 342003'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('receiving-location Edit opens the retained address chooser', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-address-sheet-route')),
      findsOneWidget,
    );
    expect(session.view, BuyV2View.checkout);
    expect(session.checkoutItemCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop and mixed Checkout keep generic delivery wording', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    for (final testCase in <({List<String> ids, BuyV2CartScope? scope})>[
      (ids: const ['s-tomato'], scope: BuyV2CartScope.shop),
      (ids: const ['s-tomato', 'w-onion'], scope: null),
    ]) {
      final session = checkout(testCase.ids, scope: testCase.scope);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(find.text('Delivering to Home'), findsOneWidget);
      expect(find.text('Receiving location · Home'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-wholesale-checkout-receiving-location')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });

  testWidgets('receiving location remains usable at compact large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final session = checkout(const ['w-onion']);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        safeArea: const EdgeInsets.symmetric(vertical: 24),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receiving location · Home'), findsOneWidget);
    final edit = find.text('Edit');
    expect(edit, findsOneWidget);
    expect(tester.getSize(edit).height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
