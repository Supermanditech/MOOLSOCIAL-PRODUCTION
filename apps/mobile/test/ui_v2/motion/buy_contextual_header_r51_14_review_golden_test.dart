import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51.14 cinematic Shop reel and context finales review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session));
    await tester.pump();
    await _capture(tester, 'r51-14-header-shop-cinematic-start');
    for (var stage = 1; stage <= 5; stage += 1) {
      await tester.pump(const Duration(milliseconds: 720));
      await _capture(tester, 'r51-14-header-shop-visual-stage-$stage');
    }
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-14-header-shop-final-multi-depth');

    for (final entry in const [
      (BuyV2Destination.wholesale, 'wholesale'),
      (BuyV2Destination.medicine, 'medicine'),
      (BuyV2Destination.orders, 'orders'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      await _capture(tester, 'r51-14-header-${entry.$2}-cinematic-mid');
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pumpAndSettle();
      await _capture(tester, 'r51-14-header-${entry.$2}-multi-depth-final');
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R51.14 compact and reduced-motion finales remain reviewable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session, textScale: 1.4));
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-14-header-shop-320-140-final');

    await tester.pumpWidget(_reviewApp(session, disableAnimations: true));
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-14-header-shop-reduced-motion-final');
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(find.text('Plan basket'), findsNothing);
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
