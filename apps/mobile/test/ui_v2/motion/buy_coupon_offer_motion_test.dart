import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

Widget host(
  BuyV2Session session, {
  bool reduced = false,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.cartScope,
    ),
  );
}

BuyV2Product shopProduct() => BuyV2Catalogue.products.firstWhere(
  (product) => product.destination == BuyV2Destination.shop,
);

Future<void> openCoupons(WidgetTester tester) async {
  final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
  await tester.scrollUntilVisible(
    coupons,
    450,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
  await tester.tap(coupons);
  await tester.pumpAndSettle();
}

Duration incomingDurationInside(WidgetTester tester, Finder owner) {
  return tester
      .widget<TweenAnimationBuilder<double>>(
        find
            .descendant(
              of: owner,
              matching: find.byType(TweenAnimationBuilder<double>),
            )
            .first,
      )
      .duration;
}

void expectTapAction(WidgetTester tester, String label) {
  final owner = find.bySemanticsLabel(label);
  expect(owner, findsOneWidget);
  expect(
    tester
        .getSemantics(owner)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap),
    isTrue,
  );
}

void main() {
  testWidgets('fail-closed unavailable contexts enter finitely', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    session.addProduct(shopProduct().id);
    session.openCart();
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();
    await openCoupons(tester);

    final empty = find.byKey(const ValueKey('buy-cart-benefit-empty-motion'));
    expect(empty, findsOneWidget);
    expect(
      tester.widget<BuyV2FiniteIncomingTransition>(empty).duration,
      BuyV2Motion.contentChange,
    );
    expect(find.text('No Shop coupons right now'), findsOneWidget);

    final kind = find.byKey(const ValueKey('buy-cart-benefit-kind-payment'));
    final kindMaterial = find.descendant(
      of: kind,
      matching: find.byType(Material),
    );
    expect(
      tester.widget<Material>(kindMaterial.first).animationDuration,
      BuyV2Motion.selection,
    );
    await tester.tap(kind);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('No Shop payment offers right now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('select replace and remove stay fixed and total-neutral', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const _AvailableBenefitsAdapter(),
    );
    session.addProduct(shopProduct().id);
    final originalTotal = session.cartTotal;
    session.openCart();
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();
    await openCoupons(tester);

    const firstId = 'provider-coupon-1';
    const secondId = 'provider-coupon-2';
    final firstCard = find.byKey(const ValueKey('buy-cart-benefit-$firstId'));
    final firstAction = find.byKey(
      const ValueKey('buy-cart-benefit-action-motion-$firstId'),
    );
    final firstStatus = find.byKey(
      const ValueKey('buy-cart-benefit-status-motion-$firstId'),
    );
    await tester.ensureVisible(firstCard);
    await tester.pumpAndSettle();
    final cardRect = tester.getRect(firstCard);
    final actionRect = tester.getRect(firstAction);
    final statusRect = tester.getRect(firstStatus);
    expectTapAction(tester, 'Select Provider coupon one');

    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-select-$firstId')),
    );
    await tester.pump(const Duration(milliseconds: 90));
    expect(session.cartTotal, originalTotal);
    expect(tester.getRect(firstCard), cardRect);
    expect(tester.getRect(firstAction), actionRect);
    expect(tester.getRect(firstStatus), statusRect);
    expect(
      incomingDurationInside(tester, firstAction),
      BuyV2Motion.stateChange,
    );
    expectTapAction(tester, 'Remove Provider coupon one');

    final secondSelect = find.byKey(
      const ValueKey('buy-cart-benefit-select-$secondId'),
    );
    await tester.ensureVisible(secondSelect);
    await tester.pumpAndSettle();
    await tester.tap(secondSelect);
    await tester.pump(const Duration(milliseconds: 90));
    expect(
      session
          .selectedCartBenefit(
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.shop,
          )
          ?.id,
      secondId,
    );
    expect(session.cartTotal, originalTotal);
    expectTapAction(tester, 'Remove Provider coupon two');

    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-remove-$secondId')),
    );
    await tester.pumpAndSettle();
    expect(
      session.selectedCartBenefit(
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
      ),
      isNull,
    );
    expect(session.cartTotal, originalTotal);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion is zero and fits 320 at 140 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const _AvailableBenefitsAdapter(),
    );
    session.addProduct(shopProduct().id);
    session.openCart();
    await tester.pumpWidget(host(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();
    await openCoupons(tester);

    final entry = find.byKey(
      const ValueKey('buy-cart-benefit-entry-motion-provider-coupon-1'),
    );
    final incoming = find.descendant(
      of: entry,
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(incoming.first).duration,
      Duration.zero,
    );
    final action = find.byKey(
      const ValueKey('buy-cart-benefit-action-motion-provider-coupon-1'),
    );
    expect(incomingDurationInside(tester, action), Duration.zero);
    final kind = find.byKey(const ValueKey('buy-cart-benefit-kind-payment'));
    final material = find.descendant(of: kind, matching: find.byType(Material));
    expect(
      tester.widget<Material>(material.first).animationDuration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });
}

class _AvailableBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  const _AvailableBenefitsAdapter();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) {
    if (kind != BuyV2CartBenefitKind.coupon ||
        !destinations.contains(BuyV2Destination.shop)) {
      return const [];
    }
    return const [
      BuyV2CartBenefit(
        id: 'provider-coupon-1',
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
        title: 'Provider coupon one',
        detail: 'Validated by the test provider.',
        sourceId: 'test-provider',
      ),
      BuyV2CartBenefit(
        id: 'provider-coupon-2',
        kind: BuyV2CartBenefitKind.coupon,
        destination: BuyV2Destination.shop,
        title: 'Provider coupon two',
        detail: 'A second validated provider choice.',
        sourceId: 'test-provider',
      ),
    ];
  }
}
