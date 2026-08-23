import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FIX11 exposes only truthful context-owned header actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    final header = find.byKey(const ValueKey('buy-contextual-glass-header'));
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(
      find.descendant(of: header, matching: find.text('Plan basket')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-header-context-cta-shop')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    Navigator.of(tester.element(find.text('Monthly home basket'))).pop();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pump();
    expect(
      find.descendant(of: header, matching: find.text('Flexible packs')),
      findsNothing,
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
    await tester.tap(
      find.byKey(const ValueKey('buy-header-context-cta-orders')),
    );
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');

    session.openDestination(BuyV2Destination.shop);
    session.openAccount();
    await tester.pump();
    expect(
      find.descendant(of: header, matching: find.text('View purchases')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-header-context-cta-shop')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX11 remains contained at 320 px and 140 percent text', (
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
      tester.getSize(find.byKey(const ValueKey('buy-header-context-slot'))),
      const Size(44, 56),
    );
    final header = find.byKey(const ValueKey('buy-contextual-glass-header'));
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(
      find.descendant(of: header, matching: find.text('Plan basket')),
      findsNothing,
    );
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX11 reduced motion resolves to one complete static frame', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    final header = find.byKey(const ValueKey('buy-contextual-glass-header'));
    expect(find.byKey(const ValueKey('buy-header-signature-shop')), findsOne);
    expect(find.bySemanticsLabel('MoolSocial'), findsNothing);
    expect(find.bySemanticsLabel('Plan a household basket'), findsOne);
    expect(
      find.descendant(of: header, matching: find.text('Plan basket')),
      findsNothing,
    );
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
