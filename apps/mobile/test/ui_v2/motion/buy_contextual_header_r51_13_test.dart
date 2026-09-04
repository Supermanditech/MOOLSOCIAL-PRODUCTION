import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FIX14 exposes icon-only truthful context actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    final header = find.byKey(const ValueKey('buy-contextual-glass-header'));
    expect(
      find.descendant(of: header, matching: find.text('Plan basket')),
      findsNothing,
    );
    expect(
      find.descendant(of: header, matching: find.text('Everyday shop')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.text('Plan the monthly basket'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-header-context-cta-shop'))),
      const Size(30, 30),
    );
    expect(find.bySemanticsLabel('Plan a household basket'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-header-context-cta-shop')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    Navigator.of(tester.element(find.text('Monthly home basket'))).pop();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pump();
    expect(
      find.descendant(of: header, matching: find.text('Lower minimums')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel('Show flexible minimum-order packs'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-header-context-cta-wholesale')),
    );
    await tester.pump();
    expect(session.selectedFilter, 'moq');

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    expect(
      find.descendant(of: header, matching: find.text('Prescription centre')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Open the prescription centre'), findsOne);
    await tester.tap(
      find.byKey(const ValueKey('buy-header-context-cta-medicine')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add your prescription'), findsOneWidget);
    Navigator.of(tester.element(find.text('Add your prescription'))).pop();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pump();
    expect(
      find.descendant(of: header, matching: find.text('Track active order')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Track active order MS-240782'), findsOne);
    await tester.tap(
      find.byKey(const ValueKey('buy-header-context-cta-orders')),
    );
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX14 exercises five finite visual slots in four contexts', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session));

    var exercisedSlots = 0;
    for (final destination in BuyV2Destination.values) {
      session.openDestination(destination);
      await tester.pump();
      for (var slot = 0; slot < 5; slot += 1) {
        await tester.pump(const Duration(milliseconds: 720));
        expect(
          find.byKey(const ValueKey('buy-header-visual-creative-reel')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        exercisedSlots += 1;
      }
    }

    expect(exercisedSlots, 20);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('FIX14 remains contained at 320 px and 140 percent text', (
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
    expect(find.bySemanticsLabel('Plan a household basket'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX14 reduced motion resolves to the complete final studio', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    expect(find.byKey(const ValueKey('buy-header-signature-shop')), findsOne);
    expect(
      find.byKey(const ValueKey('buy-header-visual-creative-reel')),
      findsOne,
    );
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(find.bySemanticsLabel('Plan a household basket'), findsOne);
    expect(find.text('Plan basket'), findsNothing);
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
