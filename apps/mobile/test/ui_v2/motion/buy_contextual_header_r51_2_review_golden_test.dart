import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51.2 staged and contextual header review', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: RepaintBoundary(
          key: const ValueKey('r51-2-header-review-boundary'),
          child: BuyV2Screen(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pump();
    await _capture(tester, 'r51-2b-header-wholesale-start');
    await tester.pump(const Duration(milliseconds: 280));
    await _capture(tester, 'r51-2b-header-wholesale-mool');
    await tester.pump(const Duration(milliseconds: 450));
    await _capture(tester, 'r51-2b-header-wholesale-social');
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-2b-header-wholesale-settled');

    for (final entry in const [
      (BuyV2Destination.shop, 'shop'),
      (BuyV2Destination.medicine, 'medicine'),
      (BuyV2Destination.orders, 'orders'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await _capture(tester, 'r51-2b-header-${entry.$2}-signature');
      await tester.pumpAndSettle();
      await _capture(tester, 'r51-2b-header-${entry.$2}-settled');
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _capture(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('r51-2-header-review-boundary')),
    matchesGoldenFile('goldens/$name.png'),
  );
}
