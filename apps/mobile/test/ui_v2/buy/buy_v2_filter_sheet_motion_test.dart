import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_filter_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            key: const ValueKey('open-filter-sheet'),
            onPressed: () => showBuyV2FilterSheet(context, session),
            child: const Text('Filters'),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(session, disableAnimations: disableAnimations, textScale: textScale),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-filter-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.6 route policy is finite and reduced motion is static', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2FilterSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2FilterSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, const Duration(milliseconds: 280));
    expect(normal.reverseDuration, const Duration(milliseconds: 220));
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
  });

  testWidgets('real catalogue tools flow reaches the R56.6 filter sheet', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2CatalogueView(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-active-orders-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-household-basket-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-filter-sheet-route')), findsOne);
    final nearby = find.byKey(const ValueKey('buy-filter-nearby'));
    await tester.scrollUntilVisible(
      nearby,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-filter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(nearby);
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'nearby');
  });

  testWidgets('selection commits once only after the reverse route', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.chooseCategory('fruits-vegetables');
    session.updateQuery('tomato');
    await openSheet(tester, session);

    final nearby = find.byKey(const ValueKey('buy-filter-nearby'));
    await tester.scrollUntilVisible(
      nearby,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-filter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(nearby);
    await tester.pump();
    expect(session.selectedFilter, isNull);
    expect(session.selectedCategoryId, 'fruits-vegetables');
    expect(session.query, 'tomato');
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.selectedFilter, isNull);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'nearby');
    expect(session.selectedCategoryId, 'fruits-vegetables');
    expect(session.query, 'tomato');
    expect(find.byKey(const ValueKey('buy-filter-sheet-route')), findsNothing);
  });

  testWidgets('unified tool action runs only after the reverse route', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2CatalogueView(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-active-orders-button')));
    await tester.pump();
    expect(session.view, BuyV2View.catalogue);
    expect(session.selectedOrderId, isNull);
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.view, BuyV2View.catalogue);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrderId, isNotNull);
  });

  testWidgets('Back, close and lifecycle never mutate filter ownership', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())..chooseFilter('returns');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(session.selectedFilter, 'returns');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'returns');

    await tester.tap(find.byKey(const ValueKey('open-filter-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-filter-close')));
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'returns');
  });

  testWidgets('stale destination cannot receive a filter from another sheet', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    final nearby = find.byKey(const ValueKey('buy-filter-nearby'));
    await tester.scrollUntilVisible(
      nearby,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-filter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(nearby);
    await tester.pumpAndSettle();

    expect(session.destination, BuyV2Destination.medicine);
    expect(session.selectedFilter, isNull);
  });

  testWidgets('named route and selected option expose one semantic owner', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession())..chooseFilter('lowest');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final route = find.byKey(const ValueKey('buy-filter-sheet-route'));
    expect(route, findsOneWidget);
    expect(tester.getSemantics(route).label, 'Shop tools and filters');
    expect(find.bySemanticsLabel('Shop tools and filters'), findsWidgets);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-filter-close'))).height,
      greaterThanOrEqualTo(44),
    );
    final selectedOwner = find.byKey(
      const ValueKey('buy-filter-semantics-lowest'),
    );
    await tester.scrollUntilVisible(
      selectedOwner,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-filter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    final selected = tester.getSemantics(selectedOwner);
    expect(selected.label, 'Lowest delivered price, selected');
    expect(selected.flagsCollection.isButton, isTrue);
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('compact 140 percent keeps the longest option reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.medicine);
    await openSheet(tester, session, textScale: 1.4);

    final sheet = find.byKey(const ValueKey('buy-filter-sheet-route'));
    expect(tester.getSize(sheet).width, lessThanOrEqualTo(320));
    final target = find.byKey(const ValueKey('buy-filter-manufacturer'));
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-filter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(58));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies and dismisses without delayed state', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.wholesale);
    await openSheet(tester, session, disableAnimations: true, settle: false);
    expect(find.byKey(const ValueKey('buy-filter-sheet-route')), findsOne);

    final freight = find.byKey(const ValueKey('buy-filter-freight'));
    await tester.scrollUntilVisible(
      freight,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-filter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(freight);
    await tester.pump();
    await tester.pump();
    expect(session.selectedFilter, 'freight');
    expect(find.byKey(const ValueKey('buy-filter-sheet-route')), findsNothing);
  });

  testWidgets('R56.6 filter-sheet responsive evidence captures', (
    tester,
  ) async {
    const cases = [
      (Size(320, 700), 1.4, false, 'compact-320x700-text140'),
      (Size(360, 800), 1.0, false, 'android-360x800'),
      (Size(390, 844), 1.0, false, 'ios-390x844'),
      (Size(390, 844), 1.0, true, 'reduced-ios-390x844'),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession());
      session.openDestination(BuyV2Destination.medicine);
      session.chooseFilter('fast');
      await openSheet(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/buy-v2-r56-6-filter-top-${capture.$4}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);

  testWidgets('R56.6 FIX3 unified-sheet responsive evidence captures', (
    tester,
  ) async {
    const cases = [
      (Size(320, 700), 1.4, false, 'compact-320x700-text140'),
      (Size(360, 800), 1.0, false, 'android-360x800'),
      (Size(390, 844), 1.0, false, 'ios-390x844'),
      (Size(390, 844), 1.0, true, 'reduced-ios-390x844'),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession());
      session.openDestination(BuyV2Destination.medicine);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                disableAnimations: capture.$3,
                textScaler: TextScaler.linear(capture.$2),
              ),
              child: child!,
            );
          },
          home: Scaffold(body: BuyV2CatalogueView(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r56-6-fix3-unified-${capture.$4}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
