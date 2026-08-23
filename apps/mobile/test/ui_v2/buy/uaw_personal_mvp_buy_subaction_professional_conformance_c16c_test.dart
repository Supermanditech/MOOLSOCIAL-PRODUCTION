import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  Future<(BuyV2Session, List<String>)> mount(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final routes = <String>[];
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
        home: BuyV2Screen(
          session: session,
          onOpenMainAction: (action) => routes.add(action.route),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (session, routes);
  }

  testWidgets(
    'Buy four-action family is standardized in one connected chooser',
    (tester) async {
      final mounted = await mount(tester, textScale: 1.4);
      final session = mounted.$1;
      final routes = mounted.$2;
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('mool-home-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      Size? standardSize;
      for (final entry in const [
        ('shop', 'Shop'),
        ('wholesale', 'Wholesale'),
        ('medicine', 'Medicine'),
        ('orders', 'Orders'),
      ]) {
        final action = find.byKey(ValueKey('mool-navigator-buy-${entry.$1}'));
        expect(action, findsOneWidget);
        final size = tester.getSize(action);
        expect(size.width, greaterThanOrEqualTo(44), reason: entry.$1);
        expect(size.height, greaterThanOrEqualTo(44), reason: entry.$1);
        standardSize ??= size;
        expect(size, standardSize, reason: entry.$1);
        final text = tester.widget<Text>(
          find.descendant(of: action, matching: find.text(entry.$2)),
        );
        expect(text.style?.fontSize, 12.5);
        expect(text.style?.fontWeight, FontWeight.w800);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(entry.$2))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      }

      await tester.tap(
        find.byKey(const ValueKey('mool-navigator-buy-wholesale')),
      );
      await tester.pumpAndSettle();
      expect(routes, ['/app/buy?sub=wholesale']);
      expect(session.destination.name, 'shop');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Buy chooser opens and dismisses immediately under reduced motion',
    (tester) async {
      await mount(tester, textScale: 1.4, reducedMotion: true);
      await tester.tap(find.byKey(const Key('mool-home-launcher')));
      await tester.pump();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('mool-connected-navigator-close')));
      await tester.pump();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
