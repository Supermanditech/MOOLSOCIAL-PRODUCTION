import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/eat/eat_services.dart';
import 'package:moolsocial/features/eat/eat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  testWidgets(
    'C24C Eat discovery candidate capture at OPPO-class viewport',
    (tester) async {
      final sessions = await _mount(
        tester,
        route: '/app/eat/home',
        size: const Size(360, 800),
        devicePixelRatio: 3,
      );
      addTearDown(sessions.dispose);
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/eat-discovery-home-c24c-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  testWidgets(
    'C24C Book Table candidate capture at OPPO-class viewport',
    (tester) async {
      final sessions = await _mount(
        tester,
        route: '/app/eat/table',
        size: const Size(360, 800),
        devicePixelRatio: 3,
      );
      addTearDown(sessions.dispose);
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/eat-book-table-c24c-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  for (final viewport in const [
    (Size(320, 568), 1.4),
    (Size(390, 844), 1.0),
    (Size(430, 932), 1.3),
  ]) {
    testWidgets(
      'C24C Order Food adapts at ${viewport.$1.width.toInt()}x${viewport.$1.height.toInt()} text ${viewport.$2}',
      (tester) async {
        final sessions = await _mount(
          tester,
          route: '/app/eat/home',
          size: viewport.$1,
          textScale: viewport.$2,
        );
        addTearDown(sessions.dispose);

        expect(find.byKey(const Key('eat-home-location')), findsOneWidget);
        expect(find.byKey(const Key('eat-home-search')), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const Key('eat-home-search-surface')))
              .height,
          greaterThanOrEqualTo(52),
        );
        expect(find.byKey(const Key('eat-home-table')), findsOneWidget);
        expect(find.text('Tiffin'), findsNothing);
        expect(find.byKey(const Key('eat-context-qr')), findsNothing);
        expect(find.byKey(const Key('eat-context-offers')), findsNothing);
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);

        expect(
          tester
              .widget<ListView>(
                find.byKey(const Key('eat-home-discovery-list')),
              )
              .scrollDirection,
          Axis.vertical,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('C24C cuisine and search lead directly to an order menu', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      route: '/app/eat/home',
      size: const Size(390, 844),
    );
    addTearDown(sessions.dispose);

    await tester.tap(find.byKey(const Key('eat-cuisine-cafe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-restaurant-blue-lime')), findsOneWidget);
    expect(find.byKey(const Key('eat-restaurant-spice-darbar')), findsNothing);

    await tester.tap(find.byKey(const Key('eat-cuisine-all')));
    await tester.enterText(find.byKey(const Key('eat-home-search')), 'Spice');
    await tester.pumpAndSettle();
    final restaurant = find.byKey(const Key('eat-restaurant-spice-darbar'));
    await _scrollTo(tester, restaurant, const Key('eat-home-discovery-list'));
    final semantics = tester.getSemantics(restaurant).getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(semantics.label, contains('4.7 rating'));
    expect(semantics.label, contains('From ₹149'));

    await tester.tap(restaurant);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-order-screen')), findsOneWidget);
    expect(sessions.eat.selectedRestaurantId, 'spice-darbar');
  });

  testWidgets('Food search owns first Android Back while keyboard is open', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      route: '/app/eat/home',
      size: const Size(360, 800),
    );
    addTearDown(sessions.dispose);

    final search = find.byKey(const Key('eat-home-search'));
    await tester.tap(search);
    await tester.enterText(search, 'Spice');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).focusNode?.hasFocus, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
    expect(tester.widget<TextField>(search).controller?.text, 'Spice');
    expect(tester.widget<TextField>(search).focusNode?.hasFocus, isFalse);
    expect(
      find.byKey(const Key('eat-restaurant-spice-darbar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('C24C Book Table keeps truthful choices and direct booking', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      route: '/app/eat/home',
      size: const Size(390, 844),
    );
    addTearDown(sessions.dispose);

    await tester.tap(find.byKey(const Key('eat-home-table')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);
    expect(find.byKey(const Key('eat-table-location')), findsOneWidget);
    expect(find.byKey(const Key('eat-table-search')), findsOneWidget);
    expect(find.byKey(const Key('eat-table-saved')), findsNothing);
    expect(find.byKey(const Key('eat-table-parking')), findsNothing);

    final closed = find.byKey(const Key('eat-table-restaurant-closed-kitchen'));
    await _scrollTo(tester, closed, const Key('eat-table-discovery-list'));
    await tester.tap(closed);
    await tester.pumpAndSettle();
    expect(sessions.eat.tableRestaurantId, 'spice-darbar');
    expect(find.textContaining('no tables today'), findsOneWidget);

    for (final key in const [
      Key('eat-table-people-6'),
      Key('eat-table-time-800PM'),
      Key('eat-table-choice-family-dining'),
    ]) {
      final target = find.byKey(key);
      await _scrollTo(tester, target, const Key('eat-table-discovery-list'));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(sessions.eat.tablePeople, '6');
    expect(sessions.eat.tableTime, '8:00 PM');
    expect(sessions.eat.tableChoice, 'Family dining');
    expect(
      tester.getSize(find.byKey(const Key('eat-book-table'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<_Sessions> _mount(
  WidgetTester tester, {
  required String route,
  required Size size,
  double textScale = 1,
  double devicePixelRatio = 1,
}) async {
  tester.view.physicalSize = size * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final journey = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'manual',
        areaLabel: 'Sardarpura',
        setupComplete: true,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );
  final eat = EatSession(
    gateway: ReviewEatOrderGateway(latency: Duration.zero),
  );
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      key: UniqueKey(),
      session: journey,
      eatSession: eat,
      initialLocation: route,
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, eat);
}

Future<void> _scrollTo(WidgetTester tester, Finder target, Key listKey) async {
  final scrollable = find.descendant(
    of: find.byKey(listKey),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    target,
    260,
    scrollable: scrollable.first,
    maxScrolls: 20,
  );
  await tester.pumpAndSettle();
}

class _Sessions {
  const _Sessions(this.journey, this.eat);

  final JourneySession journey;
  final EatSession eat;

  void dispose() {
    journey.dispose();
    eat.dispose();
  }
}
