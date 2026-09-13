import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  Future<BuyV2Session> mount(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reducedMotion,
            ),
            child: child!,
          );
        },
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('Buy local subactions share one professional geometry', (
    tester,
  ) async {
    final session = await mount(tester, textScale: 1.4);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );

    Size? standardSize;
    Rect? previousRect;
    double? standardGap;
    for (final entry in const [
      ('buy-local-tab-wholesale', 'Wholesale'),
      ('buy-local-tab-orders', 'Orders'),
      ('buy-local-tab-offers', 'Offers'),
    ]) {
      final action = find.byKey(ValueKey(entry.$1));
      expect(action, findsOneWidget);
      final size = tester.getSize(action);
      expect(size.width, greaterThanOrEqualTo(44), reason: entry.$2);
      expect(size.height, greaterThanOrEqualTo(44), reason: entry.$2);
      standardSize ??= size;
      expect(size, standardSize, reason: entry.$2);
      final rect = tester.getRect(action);
      if (previousRect != null) {
        final gap = rect.left - previousRect.right;
        standardGap ??= gap;
        expect(gap, closeTo(standardGap, .01), reason: entry.$2);
      }
      previousRect = rect;
    }

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Buy subactions replace immediately under reduced motion', (
    tester,
  ) async {
    final session = await mount(tester, textScale: 1.4, reducedMotion: true);
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pump();
    expect(session.destination, BuyV2Destination.orders);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
