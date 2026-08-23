import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/book/book_services.dart';
import 'package:moolsocial/features/book/book_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<(JourneySession, BookSession)> mount(
    WidgetTester tester, {
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    if (reducedMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
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
    final book = BookSession(
      gateway: ReviewBookGateway(latency: Duration.zero),
    );
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        bookSession: book,
        initialLocation: '/app/book/doctor',
      ),
    );
    await tester.pumpAndSettle();
    return (journey, book);
  }

  void resetEnvironment(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  }

  testWidgets('Care actions stay local and Bus remains directly reachable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    JourneySession? journey;
    BookSession? book;
    try {
      (journey, book) = await mount(tester);
      expect(
        find.byKey(const Key('care-book-local-navigation')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mool-root-selected')), findsNothing);
      expect(find.byKey(const Key('doctor-discovery-home')), findsOneWidget);
      for (final id in const ['doctor', 'medicine', 'salon']) {
        final action = find.byKey(Key('care-local-$id'));
        final size = tester.getSize(action);
        expect(size.width, greaterThanOrEqualTo(44), reason: id);
        expect(size.height, greaterThanOrEqualTo(44), reason: id);
      }
      final node = tester.getSemantics(find.bySemanticsLabel('Open Salon'));
      expect(node.label, 'Open Salon');
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      await tester.tap(find.byKey(const Key('care-local-salon')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('salon-discovery-home')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('mool-navigator-family-ride')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ride-local-bus')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bus-booking-home')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      journey?.dispose();
      book?.dispose();
      resetEnvironment(tester);
    }
  });

  testWidgets(
    'Book connected chooser opens and dismisses immediately under reduced motion',
    (tester) async {
      JourneySession? journey;
      BookSession? book;
      try {
        (journey, book) = await mount(tester, reducedMotion: true);
        final launcherMotion = tester.widget<AnimatedScale>(
          find.byKey(const Key('mool-compact-launcher-press-motion')),
        );
        expect(launcherMotion.duration, Duration.zero);
        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pump();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      } finally {
        journey?.dispose();
        book?.dispose();
        resetEnvironment(tester);
      }
    },
  );
}
