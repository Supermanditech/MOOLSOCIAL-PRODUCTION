import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FIX13 preserves the truthful context actions and geometry', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-header-context-slot'))),
      const Size(44, 56),
    );
    expect(find.text('Plan basket'), findsNothing);

    for (final entry in const [
      (BuyV2Destination.wholesale, 'Flexible packs'),
      (BuyV2Destination.medicine, 'Prescription centre'),
      (BuyV2Destination.orders, 'Track active order'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-contextual-glass-header')),
          matching: find.text(entry.$2),
        ),
        findsNothing,
      );
    }

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX13 remains contained at 320 px and 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('buy-contextual-glass-header'))),
      const Size(320, 66),
    );
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(find.text('Plan basket'), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX13 reduced motion resolves to the complete settled scene', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    expect(find.byKey(const ValueKey('buy-header-signature-shop')), findsOne);
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(find.bySemanticsLabel('Plan a household basket'), findsOne);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
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
