import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
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
    home: BuyV2Screen(session: session),
  );
}

Set<int> get allowedBrandRgb => const <int>{
  0x000080,
  0xFF9933,
  0xFFFFFF,
  0x138808,
};

int rgb(Color color) => color.toARGB32() & 0x00FFFFFF;

void main() {
  test('every Buy theme motion token derives from the four brand colours', () {
    for (final destination in BuyV2Destination.values) {
      for (final view in BuyV2View.values) {
        final spec = BuyV2ThemeSpec.resolve(destination, view);
        for (final color in <Color>[
          spec.accent,
          spec.softAccent,
          spec.canvas,
          spec.headerStart,
          spec.headerEnd,
          spec.headerForeground,
          spec.headerAccent,
          ...spec.headerGradient.colors,
          ...spec.canvasGradient.colors,
        ]) {
          expect(
            allowedBrandRgb,
            contains(rgb(color)),
            reason: '${destination.name}/${view.name}: $color',
          );
        }
      }
    }
  });

  test('vertical and downstream theme owners remain distinct', () {
    BuyV2ThemeSpec catalogue(BuyV2Destination destination) =>
        BuyV2ThemeSpec.resolve(destination, BuyV2View.catalogue);

    expect(
      catalogue(BuyV2Destination.shop).headerGradient,
      MoolBrandGradient.saffron,
    );
    expect(
      catalogue(BuyV2Destination.wholesale).headerGradient,
      MoolBrandGradient.green,
    );
    expect(
      catalogue(BuyV2Destination.medicine).headerGradient,
      MoolBrandGradient.tricolour,
    );
    expect(
      catalogue(BuyV2Destination.orders).headerGradient,
      MoolBrandGradient.navy,
    );
    expect(
      BuyV2ThemeSpec.resolve(
        BuyV2Destination.shop,
        BuyV2View.cart,
      ).headerGradient,
      MoolBrandGradient.saffron,
    );
    expect(
      BuyV2ThemeSpec.resolve(
        BuyV2Destination.orders,
        BuyV2View.tracking,
      ).headerGradient,
      MoolBrandGradient.green,
    );
  });

  testWidgets('theme changes keep header and canvas geometry fixed', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();

    final headerFinder = find.byKey(const ValueKey('buy-shared-header'));
    final canvasFinder = find.byKey(const ValueKey('buy-theme-canvas'));
    final initialHeader = tester.getRect(headerFinder);
    final initialCanvas = tester.getRect(canvasFinder);

    final changes = <VoidCallback>[
      () => session.openDestination(BuyV2Destination.wholesale),
      () => session.openDestination(BuyV2Destination.medicine),
      session.openOrders,
      session.openCart,
      () => session.openTracking('MS-240782'),
    ];
    for (final change in changes) {
      change();
      await tester.pumpAndSettle();
      expect(tester.getRect(headerFinder), initialHeader);
      expect(tester.getRect(canvasFinder), initialCanvas);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('normal transitions are finite and reduced motion is zero', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(host(session));
    await tester.pumpAndSettle();

    AnimatedContainer rootAnimation(Finder owner) =>
        tester.widget<AnimatedContainer>(
          find
              .descendant(of: owner, matching: find.byType(AnimatedContainer))
              .first,
        );

    expect(
      rootAnimation(find.byKey(const ValueKey('buy-shared-header'))).duration,
      BuyV2Motion.routeChange,
    );
    expect(
      rootAnimation(find.byKey(const ValueKey('buy-theme-canvas'))).duration,
      BuyV2Motion.contentChange,
    );

    await tester.pumpWidget(host(session, reduced: true));
    await tester.pump();
    expect(
      rootAnimation(find.byKey(const ValueKey('buy-shared-header'))).duration,
      Duration.zero,
    );
    expect(
      rootAnimation(find.byKey(const ValueKey('buy-theme-canvas'))).duration,
      Duration.zero,
    );
  });

  testWidgets('all theme owners fit at 320 pixels and 140 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(host(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final change in <VoidCallback>[
      () => session.openDestination(BuyV2Destination.shop),
      () => session.openDestination(BuyV2Destination.wholesale),
      () => session.openDestination(BuyV2Destination.medicine),
      session.openOrders,
      session.openCart,
      () => session.openTracking('MS-240782'),
    ]) {
      change();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-header-context-slot')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
