import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51.3 reference-derived staged header review', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: RepaintBoundary(
          key: const ValueKey('r51-3-header-review-boundary'),
          child: BuyV2Screen(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pump();
    await tester.pump();
    await _capture(tester, 'r51-3c-header-wholesale-start');
    await tester.pump(const Duration(milliseconds: 350));
    await _capture(tester, 'r51-3c-header-wholesale-mool');
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'r51-3c-header-wholesale-social');
    await tester.pump(const Duration(milliseconds: 550));
    await _capture(tester, 'r51-3c-header-wholesale-eyebrow');
    await tester.pump(const Duration(milliseconds: 350));
    await _capture(tester, 'r51-3c-header-wholesale-copy-handoff');
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-3c-header-wholesale-settled');

    for (final entry in const [
      (BuyV2Destination.shop, 'shop'),
      (BuyV2Destination.medicine, 'medicine'),
      (BuyV2Destination.orders, 'orders'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 760));
      await _capture(tester, 'r51-3c-header-${entry.$2}-scene');
      await tester.pumpAndSettle();
      await _capture(tester, 'r51-3c-header-${entry.$2}-settled');
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _capture(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('r51-3-header-review-boundary')),
    matchesGoldenFile('goldens/$name.png'),
  );
}
