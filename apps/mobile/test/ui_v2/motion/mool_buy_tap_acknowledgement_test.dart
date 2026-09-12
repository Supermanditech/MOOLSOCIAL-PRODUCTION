import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/motion/mool_buy_tap_acknowledgement.dart';

void main() {
  testWidgets(
    'Buy wrapper adds no pointer visual and passes taps immediately',
    (tester) async {
      final route = ValueNotifier(
        RouteInformation(uri: Uri.parse('/app/buy?destination=shop')),
      );
      addTearDown(route.dispose);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: MoolBuyTapAcknowledgement(
            routeInformation: route,
            child: Material(
              child: InkWell(
                key: const Key('bounded-action'),
                onTap: () => taps += 1,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('bounded-action')));
      expect(taps, 1);
      expect(find.byKey(const ValueKey('mool-buy-tap-visual')), findsNothing);
      expect(find.byKey(const ValueKey('mool-buy-tap-ring')), findsNothing);
    },
  );

  testWidgets('wrapper preserves the underlying action semantics', (
    tester,
  ) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/app/buy')));
    addTearDown(route.dispose);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: MoolBuyTapAcknowledgement(
          routeInformation: route,
          child: Semantics(
            label: 'Underlying action',
            button: true,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Underlying action'), findsOneWidget);
    semantics.dispose();
  });

  test('global and Buy source reject sparkle and tricolour pointer rings', () {
    final theme = File('lib/core/design/mool_theme.dart').readAsStringSync();
    final acknowledgement = File(
      'lib/ui_v2/motion/mool_buy_tap_acknowledgement.dart',
    ).readAsStringSync();

    expect(theme, contains('NoSplash.splashFactory'));
    expect(theme, isNot(contains('InkSparkle.splashFactory')));
    expect(acknowledgement, isNot(contains('_MoolTapRingPainter')));
    expect(acknowledgement, isNot(contains('CustomPaint')));
    expect(acknowledgement, isNot(contains('PointerDownEvent')));
  });
}
