import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  testWidgets(
    'C24B2 candidate capture at OPPO-class viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: PersonalMoolRootV2(
            onBack: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
            onOpenRoute: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('personal-mool-root-v2')),
        matchesGoldenFile(
          'candidate_captures/mool-home-c24b2-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  for (final viewport in const [
    (size: Size(320, 568), textScale: 1.4),
    (size: Size(390, 844), textScale: 1.0),
    (size: Size(430, 932), textScale: 1.3),
  ]) {
    testWidgets(
      'C24B2 fixed Home fits ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final routes = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: viewport.size,
                textScaler: TextScaler.linear(viewport.textScale),
              ),
              child: PersonalMoolRootV2(
                onBack: () {},
                onOpenAction: (_) {},
                onOpenChat: () {},
                onOpenRoute: routes.add,
                areaLabel: 'Jodhpur',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(CustomScrollView), findsNothing);
        expect(find.byType(GridView), findsNothing);
        expect(find.byType(PageView), findsNothing);
        expect(
          find.byKey(const Key('mool-home-main-actions-only')),
          findsOneWidget,
        );
        for (final family in const [
          'social',
          'buy',
          'eat',
          'ride',
          'book',
          'work',
        ]) {
          expect(
            find.byKey(ValueKey('mool-home-family-$family')),
            findsOneWidget,
          );
        }
        expect(find.text('MoolSocial'), findsNothing);
        expect(find.text('Home'), findsNothing);
        expect(find.text('Your Mool'), findsNothing);
        expect(find.textContaining('Products, services'), findsNothing);
        expect(find.text('Your area'), findsNothing);
        expect(find.text('Jodhpur'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('C25F opens a main domain directly and keeps subactions local', (
    tester,
  ) async {
    final routes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalMoolRootV2(
          onBack: () {},
          onOpenAction: (_) {},
          onOpenChat: () {},
          onOpenRoute: routes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mool-home-social-shorts')), findsNothing);
    expect(find.byKey(const ValueKey('mool-home-buy-shop')), findsNothing);
    expect(
      find.byKey(const ValueKey('mool-home-main-actions-only')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Open Shop'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('mool-home-family-buy')));
    await tester.pump();
    expect(routes, ['/app/buy?sub=shop']);
    expect(find.byKey(const ValueKey('mool-home-social-shorts')), findsNothing);
    expect(find.byKey(const ValueKey('mool-home-buy-shop')), findsNothing);
  });
}
