import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';
import 'package:moolsocial/features/book/book_models.dart';
import 'package:moolsocial/features/book/book_services.dart';
import 'package:moolsocial/features/book/book_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  for (final capture in const [
    ('doctor', '/app/book/doctor'),
    ('salon', '/app/book/salon'),
  ]) {
    testWidgets(
      'C24E ${capture.$1} candidate capture at OPPO-class viewport',
      (tester) async {
        final sessions = await _mount(
          tester,
          route: capture.$2,
          size: const Size(360, 800),
          devicePixelRatio: 3,
        );
        addTearDown(sessions.dispose);
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            'candidate_captures/book-${capture.$1}-home-c24e-oppo-360x800.png',
          ),
        );
      },
      // Run explicitly with --run-skipped --update-goldens for visual evidence.
      skip: true,
    );
  }

  for (final viewport in const [
    (Size(320, 568), 1.4),
    (Size(390, 844), 1.0),
    (Size(430, 932), 1.3),
  ]) {
    testWidgets(
      'C24E Doctor adapts at ${viewport.$1.width.toInt()}x${viewport.$1.height.toInt()} text ${viewport.$2}',
      (tester) async {
        final sessions = await _mount(
          tester,
          route: '/app/book/doctor',
          size: viewport.$1,
          textScale: viewport.$2,
        );
        addTearDown(sessions.dispose);

        expect(find.byKey(const Key('doctor-discovery-home')), findsOneWidget);
        expect(find.byKey(const Key('doctor-search')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('doctor-search'))).height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight),
        );
        for (final key in const [
          Key('doctor-care-clinic'),
          Key('doctor-care-opd'),
          Key('doctor-care-video'),
          Key('doctor-care-followUp'),
          Key('doctor-need-fever'),
        ]) {
          await _scrollTo(
            tester,
            find.byKey(key),
            const Key('doctor-discovery-home'),
          );
          expect(
            tester.getSize(find.byKey(key)).height,
            greaterThanOrEqualTo(44),
          );
        }
        expect(
          tester.getSize(find.byKey(const Key('book-doctor'))).height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.primaryActionHeight),
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        final medicine = find.byKey(const Key('care-local-medicine'));
        expect(medicine, findsOneWidget);
        expect(tester.getSize(medicine).height, greaterThanOrEqualTo(44));
        expect(find.text('Get It Done'), findsNothing);
        expect(
          tester
              .widget<ListView>(find.byKey(const Key('doctor-discovery-home')))
              .scrollDirection,
          Axis.vertical,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'C24E Salon adapts at ${viewport.$1.width.toInt()}x${viewport.$1.height.toInt()} text ${viewport.$2}',
      (tester) async {
        final sessions = await _mount(
          tester,
          route: '/app/book/salon',
          size: viewport.$1,
          textScale: viewport.$2,
        );
        addTearDown(sessions.dispose);

        expect(find.byKey(const Key('salon-discovery-home')), findsOneWidget);
        expect(find.byKey(const Key('salon-search')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('salon-search'))).height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight),
        );
        for (final key in const [
          Key('salon-service-haircut'),
          Key('salon-service-beard'),
          Key('salon-mode-salon'),
          Key('salon-mode-home'),
        ]) {
          await _scrollTo(
            tester,
            find.byKey(key),
            const Key('salon-discovery-home'),
          );
          expect(
            tester.getSize(find.byKey(key)).height,
            greaterThanOrEqualTo(44),
          );
        }
        expect(
          tester.getSize(find.byKey(const Key('review-salon-slot'))).height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.primaryActionHeight),
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(
          tester
              .widget<ListView>(find.byKey(const Key('salon-discovery-home')))
              .scrollDirection,
          Axis.vertical,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('C24E Doctor search and provider remain direct and truthful', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final sessions = await _mount(
      tester,
      route: '/app/book/doctor',
      size: const Size(390, 844),
    );
    try {
      await tester.enterText(find.byKey(const Key('doctor-search')), 'Skin');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('doctor-need-skin')), findsOneWidget);
      expect(find.byKey(const Key('doctor-need-fever')), findsNothing);
      await tester.tap(find.byKey(const Key('doctor-need-skin')));
      await tester.pumpAndSettle();
      expect(sessions.book.doctorNeed, 'Skin');

      await tester.enterText(
        find.byKey(const Key('doctor-search')),
        'Orthopaedic',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('doctor-search-empty')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('doctor-search')), '');
      await tester.pumpAndSettle();

      final provider = find.byKey(const Key('doctor-top-provider'));
      await _scrollTo(tester, provider, const Key('doctor-discovery-home'));
      final data = tester.getSemantics(provider).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.label, contains('verified general physician'));
      expect(data.label, contains('₹300'));
      expect(data.label, contains('12 minute wait'));
      await tester.tap(provider);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('patient-self')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      sessions.dispose();
    }
  });

  testWidgets('Doctor keeps Video selected through details and native Back', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      route: '/app/book/doctor',
      size: const Size(360, 800),
    );
    addTearDown(sessions.dispose);

    await tester.tap(find.byKey(const Key('doctor-care-video')));
    await tester.pumpAndSettle();
    expect(sessions.book.doctorCare, DoctorCare.video);
    expect(find.text('Continue with Video'), findsOneWidget);

    await tester.tap(find.byKey(const Key('book-doctor')));
    await tester.pumpAndSettle();
    expect(
      find.text('Video · ₹300 · doctor registration verified'),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('doctor-care-video')), findsOneWidget);
    expect(sessions.book.doctorCare, DoctorCare.video);
    expect(find.text('Continue with Video'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C24E Salon search updates the direct price and booking choice', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final sessions = await _mount(
      tester,
      route: '/app/book/salon',
      size: const Size(390, 844),
    );
    try {
      await tester.enterText(find.byKey(const Key('salon-search')), 'Facial');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('salon-service-facial')), findsOneWidget);
      expect(find.byKey(const Key('salon-service-haircut')), findsNothing);
      await tester.tap(find.byKey(const Key('salon-service-facial')));
      await tester.pumpAndSettle();
      expect(sessions.book.salonService, 'Facial');
      expect(sessions.book.salonAmount, 499);

      await tester.enterText(find.byKey(const Key('salon-search')), 'Nails');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('salon-search-empty')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('salon-search')), '');
      await tester.pumpAndSettle();

      final provider = find.byKey(const Key('salon-top-provider'));
      await _scrollTo(tester, provider, const Key('salon-discovery-home'));
      final data = tester.getSemantics(provider).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.label, contains('verified'));
      expect(data.label, contains('₹499'));
      expect(data.label, contains('free cancellation'));
      await tester.tap(provider);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-salon-slot')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      sessions.dispose();
    }
  });

  testWidgets('C24E service-card motion is immediate when reduced', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      route: '/app/book/doctor',
      size: const Size(390, 844),
      reduceMotion: true,
    );
    addTearDown(sessions.dispose);

    final provider = find.byKey(const Key('doctor-top-provider'));
    await _scrollTo(tester, provider, const Key('doctor-discovery-home'));
    final motion = find.descendant(
      of: provider,
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.widget<AnimatedContainer>(motion).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}

Future<_Sessions> _mount(
  WidgetTester tester, {
  required String route,
  required Size size,
  double textScale = 1,
  double devicePixelRatio = 1,
  bool reduceMotion = false,
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
  final book = BookSession(gateway: ReviewBookGateway(latency: Duration.zero));
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      key: UniqueKey(),
      session: journey,
      bookSession: book,
      initialLocation: route,
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, book);
}

Future<void> _scrollTo(WidgetTester tester, Finder target, Key listKey) async {
  final scrollable = find.descendant(
    of: find.byKey(listKey),
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
  const _Sessions(this.journey, this.book);

  final JourneySession journey;
  final BookSession book;

  void dispose() {
    journey.dispose();
    book.dispose();
  }
}
