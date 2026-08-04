import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viewport in const [
    (Size(390, 844), 1.0, '390'),
    (Size(320, 568), 1.4, '320-140'),
  ]) {
    testWidgets('R51.8 borderless progressive Search ${viewport.$3}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport.$1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(_reviewApp(session, textScale: viewport.$2));
      await tester.pumpAndSettle();

      final restingDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(restingDecoration.color, Colors.transparent);
      expect(restingDecoration.border, isNull);
      expect(restingDecoration.boxShadow, isNull);

      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'monthly grocery basket with medicines and wholesale supplies',
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
        viewport.$2 >= 1.3 ? 150 : 120,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-band'))).height,
        viewport.$2 >= 1.3 ? 162 : 132,
      );
      final activeDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(activeDecoration.color, Colors.transparent);
      expect(activeDecoration.border, isNull);
      expect(activeDecoration.boxShadow, isNull);
      final inputDecoration = tester
          .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
          .decoration!;
      expect(inputDecoration.border, InputBorder.none);
      expect(inputDecoration.enabledBorder, InputBorder.none);
      expect(inputDecoration.focusedBorder, InputBorder.none);
      expect(inputDecoration.errorBorder, InputBorder.none);
      expect(inputDecoration.focusedErrorBorder, InputBorder.none);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
            .maxLines,
        6,
      );
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
      await expectLater(
        find.byKey(const ValueKey('r51-8-search-review-boundary')),
        matchesGoldenFile('goldens/r51-8-search-long-query-${viewport.$3}.png'),
      );
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _reviewApp(BuyV2Session session, {required double textScale}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: RepaintBoundary(
      key: const ValueKey('r51-8-search-review-boundary'),
      child: BuyV2Screen(session: session),
    ),
  );
}
