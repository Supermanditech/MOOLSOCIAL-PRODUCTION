import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51.11 all-corner depth and stacked brand review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session));
    await tester.pump();
    await _capture(tester, 'r51-11-header-shop-start');
    await tester.pump(const Duration(milliseconds: 700));
    await _capture(tester, 'r51-11-header-shop-mool-arrival');
    await tester.pump(const Duration(milliseconds: 850));
    await _capture(tester, 'r51-11-header-shop-social-arrival');
    await tester.pump(const Duration(milliseconds: 900));
    await _capture(tester, 'r51-11-header-shop-depth-action');
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-11-header-shop-settled-stacked-brand');

    for (final entry in const [
      (BuyV2Destination.wholesale, 'wholesale'),
      (BuyV2Destination.medicine, 'medicine'),
      (BuyV2Destination.orders, 'orders'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await _capture(tester, 'r51-11-header-${entry.$2}-all-corner-depth');
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      await _capture(tester, 'r51-11-header-${entry.$2}-settled-stacked-brand');
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R51.11 320 at 140 percent remains reviewable', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session, textScale: 1.4));
    await tester.pumpAndSettle();

    await _capture(tester, 'r51-11-header-shop-320-140-stacked');
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R51.11 reduced motion resolves to the deep final scene', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session, disableAnimations: true));
    await tester.pump();

    await _capture(tester, 'r51-11-header-shop-reduced-motion-430');
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

Widget _reviewApp(
  BuyV2Session session, {
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: BuyV2Screen(session: session),
  );
}

Future<void> _capture(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('buy-contextual-glass-header')),
    matchesGoldenFile('goldens/$name.png'),
  );
}
