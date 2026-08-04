import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R51.6 strong drum and four-plane context review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.shop);
    await tester.pump();
    await tester.pump();
    await _capture(tester, 'r51-6-header-shop-mool-dwell');
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 410));
    await _capture(tester, 'r51-6-header-shop-drum-turn');
    await tester.pump(const Duration(milliseconds: 410));
    await _capture(tester, 'r51-6-header-shop-social-dwell');
    await tester.pump(const Duration(milliseconds: 1580));
    await tester.pumpAndSettle();
    await _capture(tester, 'r51-6-header-shop-settled');

    for (final entry in const [
      (BuyV2Destination.wholesale, 'wholesale'),
      (BuyV2Destination.medicine, 'medicine'),
      (BuyV2Destination.orders, 'orders'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      await _capture(tester, 'r51-6-header-${entry.$2}-middle-plane');
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();
      await _capture(tester, 'r51-6-header-${entry.$2}-settled');
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R51.6 compact 320 at 140 percent remains contained', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_reviewApp(session, textScale: 1.4));
    await tester.pumpAndSettle();

    await _capture(tester, 'r51-6-header-shop-320-140-settled');
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
      key: const ValueKey('r51-6-header-review-boundary'),
      child: BuyV2Screen(session: session),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String _) async {
  expect(find.byKey(const ValueKey('buy-shared-header')), findsOneWidget);
  expect(find.byKey(const ValueKey('buy-search-control')), findsOneWidget);
  await tester.pump();
}
