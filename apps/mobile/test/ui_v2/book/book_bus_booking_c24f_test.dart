import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';
import 'package:moolsocial/features/book/book_services.dart';
import 'package:moolsocial/features/book/book_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  testWidgets(
    'C24F Bus home candidate capture at OPPO-class viewport',
    (tester) async {
      final sessions = await _mount(
        tester,
        size: const Size(360, 800),
        devicePixelRatio: 3,
      );
      addTearDown(sessions.dispose);
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/book-bus-home-c24f-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  testWidgets(
    'C24F Bus results candidate capture at OPPO-class viewport',
    (tester) async {
      final sessions = await _mount(
        tester,
        size: const Size(360, 800),
        devicePixelRatio: 3,
      );
      addTearDown(sessions.dispose);
      await tester.tap(find.byKey(const Key('bus-search')));
      await tester.pumpAndSettle();
      final first = find.byKey(const Key('bus-trip-BUS-20260809-1'));
      await _scrollTo(tester, first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/book-bus-results-c24f-oppo-360x800.png',
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
      'C24F Bus adapts at ${viewport.$1.width.toInt()}x${viewport.$1.height.toInt()} text ${viewport.$2}',
      (tester) async {
        final sessions = await _mount(
          tester,
          size: viewport.$1,
          textScale: viewport.$2,
        );
        addTearDown(sessions.dispose);

        expect(find.byKey(const Key('bus-booking-home')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('bus-from'))).height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight),
        );
        for (final key in const [
          Key('bus-from'),
          Key('bus-swap'),
          Key('bus-to'),
          Key('bus-date-today'),
          Key('bus-date-tomorrow'),
          Key('bus-date'),
        ]) {
          await _scrollTo(tester, find.byKey(key));
          expect(
            tester.getSize(find.byKey(key)).height,
            greaterThanOrEqualTo(44),
          );
        }
        expect(
          tester.getSize(find.byKey(const Key('bus-search'))).height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.primaryActionHeight),
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.text('Medicine'), findsNothing);
        expect(find.text('Get It Done'), findsNothing);
        expect(
          tester
              .widget<ListView>(find.byKey(const Key('bus-booking-home')))
              .scrollDirection,
          Axis.vertical,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bus-booking-home')),
            matching: find.byType(PageView),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'C24F swap, Tomorrow and search retain one truthful route state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final sessions = await _mount(tester, size: const Size(390, 844));
      try {
        await tester.tap(find.byKey(const Key('bus-swap')));
        await tester.pumpAndSettle();
        expect(sessions.book.busFrom, 'Jaipur');
        expect(sessions.book.busTo, 'Jodhpur');
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('bus-from')))
              .controller!
              .text,
          'Jaipur',
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('bus-to')))
              .controller!
              .text,
          'Jodhpur',
        );

        await tester.tap(find.byKey(const Key('bus-date-tomorrow')));
        await tester.pumpAndSettle();
        expect(sessions.book.busDayOffset, 1);
        await tester.tap(find.byKey(const Key('bus-search')));
        await tester.pumpAndSettle();

        expect(sessions.gateway.busSearchCalls, 1);
        expect(sessions.book.busResults, hasLength(2));
        final first = find.byKey(const Key('bus-trip-BUS-20260810-1'));
        await _scrollTo(tester, first);
        expect(tester.getSize(first).height, greaterThanOrEqualTo(44));
        var data = tester.getSemantics(first).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        for (final truth in const [
          'BlueCity Express',
          '06:30',
          '12:15',
          '5h 45m',
          '12 seats shown',
          '4.5 rating',
          '₹649',
          'confirmed only at checkout',
        ]) {
          expect(data.label, contains(truth));
        }

        await tester.tap(first);
        await tester.pumpAndSettle();
        expect(sessions.book.selectedBusId, 'BUS-20260810-1');
        data = tester.getSemantics(first).getSemanticsData();
        expect(data.label, contains('Selected for review'));
        expect(sessions.book.noticeMessage, contains('No payment was taken'));
        expect(sessions.book.noticeMessage, contains('no ticket was issued'));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
        sessions.dispose();
      }
    },
  );

  testWidgets(
    'C24F invalid and failed searches recover without false results',
    (tester) async {
      final sessions = await _mount(
        tester,
        size: const Size(390, 844),
        failNextBus: true,
      );
      addTearDown(sessions.dispose);

      await tester.enterText(find.byKey(const Key('bus-to')), 'Jodhpur');
      await tester.tap(find.byKey(const Key('bus-search')));
      await tester.pumpAndSettle();
      expect(sessions.gateway.busSearchCalls, 0);
      expect(sessions.book.busResults, isEmpty);
      expect(sessions.book.errorMessage, contains('must be different'));

      await tester.enterText(find.byKey(const Key('bus-to')), 'Jaipur');
      await tester.tap(find.byKey(const Key('bus-search')));
      await tester.pumpAndSettle();
      expect(sessions.gateway.busSearchCalls, 1);
      expect(sessions.book.busResults, isEmpty);
      expect(sessions.book.errorMessage, contains('route and date are saved'));

      await tester.tap(find.byKey(const Key('bus-search')));
      await tester.pumpAndSettle();
      expect(sessions.gateway.busSearchCalls, 2);
      expect(sessions.book.busResults, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OPPO Bus selection completes a truthful request and native return',
    (tester) async {
      final sessions = await _mount(tester, size: const Size(360, 800));
      addTearDown(sessions.dispose);

      await tester.tap(find.byKey(const Key('bus-search')));
      await tester.pumpAndSettle();
      final first = find.byKey(const Key('bus-trip-BUS-20260809-1'));
      await _scrollTo(tester, first);
      await tester.tap(first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bus-review')), findsOneWidget);
      await tester.tap(find.byKey(const Key('bus-review')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bus-review-screen')), findsOneWidget);
      expect(find.text('Live checkout required'), findsOneWidget);
      expect(
        find.text('A preference is not a confirmed seat.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('bus-passengers-2')));
      await tester.tap(find.byKey(const Key('bus-seat-aisle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bus-prepare-request')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bus-request-ready-screen')), findsOneWidget);
      expect(find.text('Booking request ready'), findsOneWidget);
      expect(find.text('No payment or ticket yet'), findsOneWidget);
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
      expect(find.textContaining('UI review'), findsNothing);
      expect(find.text('₹0 charged'), findsOneWidget);
      expect(sessions.book.noticeMessage, contains('No payment was taken'));
      expect(sessions.book.noticeMessage, contains('no ticket was issued'));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bus-review-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bus-booking-home')), findsOneWidget);
      expect(find.byKey(const Key('bus-review')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C24F result motion is immediate when reduced', (tester) async {
    final sessions = await _mount(
      tester,
      size: const Size(390, 844),
      reduceMotion: true,
    );
    addTearDown(sessions.dispose);

    final motion = tester.widget<AnimatedSwitcher>(
      find.byKey(const Key('bus-results-motion')),
    );
    expect(motion.duration, Duration.zero);
    await tester.tap(find.byKey(const Key('bus-search')));
    await tester.pump();
    expect(sessions.book.busResults, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

Future<_Sessions> _mount(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  double devicePixelRatio = 1,
  bool reduceMotion = false,
  bool failNextBus = false,
}) async {
  tester.view.physicalSize = size * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (reduceMotion) {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

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
  final gateway = ReviewBookGateway(
    latency: Duration.zero,
    failNextBus: failNextBus,
  );
  final book = BookSession(
    gateway: gateway,
    now: () => DateTime(2026, 8, 9, 10, 30),
  );
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      key: UniqueKey(),
      session: journey,
      bookSession: book,
      initialLocation: '/app/book/bus',
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, book, gateway);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scrollable = find.descendant(
    of: find.byKey(const Key('bus-booking-home')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: scrollable.first,
    maxScrolls: 20,
  );
  await tester.pumpAndSettle();
}

class _Sessions {
  const _Sessions(this.journey, this.book, this.gateway);

  final JourneySession journey;
  final BookSession book;
  final ReviewBookGateway gateway;

  void dispose() {
    journey.dispose();
    book.dispose();
  }
}
