import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51.4 single-slot identity and deep storyboard review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pump();
    await tester.pump();
    await _capture(tester, 'r51-4d-header-wholesale-start');
    await tester.pump(const Duration(milliseconds: 350));
    await _capture(tester, 'r51-4d-header-wholesale-mool');
    await tester.pump(const Duration(milliseconds: 1000));
    await _capture(tester, 'r51-4d-header-wholesale-social');
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, 'r51-4d-header-wholesale-feature-one');
    await tester.pump(const Duration(milliseconds: 600));
    await _capture(tester, 'r51-4d-header-wholesale-feature-two');
    await tester.pump(const Duration(milliseconds: 600));
    await _capture(tester, 'r51-4d-header-wholesale-context-rail');
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-4d-header-wholesale-settled');

    for (final entry in const [
      (BuyV2Destination.shop, 'shop'),
      (BuyV2Destination.medicine, 'medicine'),
      (BuyV2Destination.orders, 'orders'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1350));
      await _capture(tester, 'r51-4d-header-${entry.$2}-depth');
      await tester.pumpAndSettle();
      await _capture(tester, 'r51-4d-header-${entry.$2}-settled');
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R51.4 compact 320 at 140 percent remains contained', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session, textScale: 1.4));
    await tester.pumpAndSettle();

    await _capture(tester, 'r51-4d-header-shop-320-140-settled');
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

Widget _reviewApp(BuyV2Session session, {double textScale = 1}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: RepaintBoundary(
      key: const ValueKey('r51-4-header-review-boundary'),
      child: BuyV2Screen(session: session),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('r51-4-header-review-boundary')),
    matchesGoldenFile('goldens/$name.png'),
  );
}
