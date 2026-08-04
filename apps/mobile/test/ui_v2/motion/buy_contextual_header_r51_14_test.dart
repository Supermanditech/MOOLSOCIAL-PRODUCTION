import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FIX15 makes all twenty visual promo stages truthful actions', (
    tester,
  ) async {
    const stageTimes = <Duration>[
      Duration.zero,
      Duration(milliseconds: 720),
      Duration(milliseconds: 864),
      Duration(milliseconds: 1080),
      Duration(milliseconds: 1620),
    ];

    var exercisedStages = 0;
    for (final destination in BuyV2Destination.values) {
      for (var slot = 0; slot < 5; slot += 1) {
        final session = BuyV2Session(core: BuySession());
        await tester.pumpWidget(_app(session));
        if (destination != BuyV2Destination.shop) {
          session.openDestination(destination);
          await tester.pump();
        }
        await tester.pump(stageTimes[slot]);

        final promo = find.byKey(
          ValueKey<String>(
            'buy-header-promo-stage-action-${destination.name}-$slot',
          ),
        );
        expect(promo, findsOneWidget);
        expect(
          find.bySemanticsLabel(
            '${destination.label} visual promotion ${slot + 1} of 5. '
            '${_actionSemantics(destination)}',
          ),
          findsOneWidget,
        );

        await tester.tap(promo);
        await tester.pump();
        switch (destination) {
          case BuyV2Destination.shop:
            await tester.pumpAndSettle();
            expect(find.text('Monthly home basket'), findsOneWidget);
            Navigator.of(
              tester.element(find.text('Monthly home basket')),
            ).pop();
          case BuyV2Destination.wholesale:
            expect(session.selectedFilter, 'moq');
          case BuyV2Destination.medicine:
            await tester.pumpAndSettle();
            expect(find.text('Add your prescription'), findsOneWidget);
            Navigator.of(
              tester.element(find.text('Add your prescription')),
            ).pop();
          case BuyV2Destination.orders:
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.tracking);
            expect(session.selectedOrder.id, 'MS-240782');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        exercisedStages += 1;
      }
    }

    expect(exercisedStages, 20);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('FIX15 keeps the accepted compact header and Search boundary', (
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
    expect(find.bySemanticsLabel('MoolSocial'), findsOneWidget);
    expect(find.text('Plan basket'), findsNothing);
    expect(
      find.bySemanticsLabel(
        'Shop visual promotion 5 of 5. Plan a household basket',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX15 reduced motion is final, tappable and ticker-free', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(_app(session, disableAnimations: true));
    await tester.pump();

    final finalPromo = find.byKey(
      const ValueKey('buy-header-promo-stage-action-shop-4'),
    );
    expect(finalPromo, findsOneWidget);
    expect(find.bySemanticsLabel('MoolSocial'), findsOneWidget);
    await tester.tap(finalPromo);
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}

String _actionSemantics(BuyV2Destination destination) => switch (destination) {
  BuyV2Destination.shop => 'Plan a household basket',
  BuyV2Destination.wholesale => 'Show flexible minimum-order packs',
  BuyV2Destination.medicine => 'Open the prescription centre',
  BuyV2Destination.orders => 'Track active order MS-240782',
};

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
