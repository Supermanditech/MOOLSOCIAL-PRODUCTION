import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_models.dart';
import 'package:moolsocial/features/ride/ride_services.dart';
import 'package:moolsocial/features/ride/ride_session.dart';

void main() {
  testWidgets(
    'C24D Ride destination candidate capture at OPPO-class viewport',
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
          'candidate_captures/ride-destination-home-c24d-oppo-360x800.png',
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
      'C24D Ride adapts at ${viewport.$1.width.toInt()}x${viewport.$1.height.toInt()} text ${viewport.$2}',
      (tester) async {
        final sessions = await _mount(
          tester,
          size: viewport.$1,
          textScale: viewport.$2,
        );
        addTearDown(sessions.dispose);

        expect(find.byKey(const Key('ride-current-pickup')), findsOneWidget);
        expect(
          find.byKey(const Key('ride-destination-search')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(find.byKey(const Key('ride-destination-search-surface')))
              .height,
          greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight),
        );
        expect(
          tester.getSize(find.byKey(const Key('ride-edit-route'))).height,
          greaterThanOrEqualTo(44),
        );
        final savedHome = find.byKey(const Key('ride-place-home'));
        await _scrollTo(tester, savedHome);
        expect(savedHome, findsOneWidget);
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.byKey(const Key('ride-map')), findsNothing);
        expect(find.byKey(const Key('ride-promo')), findsNothing);
        expect(
          tester
              .widget<ListView>(find.byKey(const Key('ride-booking-screen')))
              .scrollDirection,
          Axis.vertical,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('OPPO header keeps the complete Ride instruction visible', (
    tester,
  ) async {
    final sessions = await _mount(tester, size: const Size(360, 800));
    addTearDown(sessions.dispose);

    final subtitle = find.byKey(const Key('ride-page-subtitle'));
    expect(find.text('Destination, vehicle and fare'), findsOneWidget);
    final subtitleRect = tester.getRect(subtitle);
    final appBarRect = tester.getRect(find.byType(AppBar));
    expect(subtitleRect.left, greaterThanOrEqualTo(appBarRect.left));
    expect(subtitleRect.right, lessThanOrEqualTo(appBarRect.right));
    expect(subtitleRect.bottom, lessThanOrEqualTo(appBarRect.bottom));
    expect(subtitleRect.height, lessThan(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('C24D recent and saved places set the destination in one tap', (
    tester,
  ) async {
    final sessions = await _mount(tester, size: const Size(390, 844));
    addTearDown(sessions.dispose);

    final savedHome = find.byKey(const Key('ride-place-home'));
    await _scrollTo(tester, savedHome);
    final semantics = tester.getSemantics(savedHome).getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(semantics.label, contains('Saved place'));
    await tester.tap(savedHome);
    await tester.pumpAndSettle();

    expect(sessions.ride.drop, 'Sardarpura, Jodhpur');
    final destination = find.byKey(
      const Key('ride-destination-search-surface'),
    );
    await _scrollBackTo(tester, destination);
    expect(
      tester.getSemantics(destination).getSemanticsData().label,
      contains('Selected Sardarpura, Jodhpur'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('C24D vehicle cards expose truthful comparison before booking', (
    tester,
  ) async {
    final sessions = await _mount(tester, size: const Size(390, 844));
    addTearDown(sessions.dispose);

    final cab = find.byKey(const Key('ride-type-cab'));
    await _scrollTo(tester, cab);
    expect(tester.getSize(cab).height, greaterThanOrEqualTo(44));
    await tester.tap(cab);
    await tester.pumpAndSettle();
    expect(sessions.ride.selectedType, RideType.cab);

    final package = sessions.ride.selectedPackage;
    final packageCard = find.byKey(Key('ride-package-${package.id}'));
    await _scrollTo(tester, packageCard);
    final semantics = tester.getSemantics(packageCard).getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(semantics.label, contains('₹${package.fare}'));
    expect(semantics.label, contains('${package.arrivalMinutes} minutes'));
    expect(semantics.label, contains(package.capacity));
    expect(semantics.label, contains('captains nearby'));

    final upi = find.byKey(const Key('ride-payment-upi'));
    await _scrollTo(tester, upi);
    expect(tester.getSize(upi).height, greaterThanOrEqualTo(44));
    await tester.tap(upi);
    await tester.pumpAndSettle();
    expect(sessions.ride.paymentMethod, RidePaymentMethod.upi);
    expect(
      tester.getSize(find.byKey(const Key('ride-book'))).height,
      greaterThanOrEqualTo(MoolServiceHomeTokens.primaryActionHeight),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('C24D reduced motion applies destination changes immediately', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      size: const Size(390, 844),
      reduceMotion: true,
    );
    addTearDown(sessions.dispose);

    final aiims = find.byKey(const Key('ride-place-aiims-jodhpur'));
    await _scrollTo(tester, aiims);
    expect(
      MoolServiceHomeTokens.accessibleDuration(tester.element(aiims)),
      Duration.zero,
    );
    await tester.tap(aiims);
    await tester.pump();
    expect(sessions.ride.drop, 'AIIMS Jodhpur main entrance');
    expect(tester.takeException(), isNull);
  });
}

Future<_Sessions> _mount(
  WidgetTester tester, {
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
  final ride = RideSession(gateway: ReviewRideGateway(latency: Duration.zero));
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      key: UniqueKey(),
      session: journey,
      rideSession: ride,
      initialLocation: '/app/ride/book?type=auto',
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, ride);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scrollable = find.descendant(
    of: find.byKey(const Key('ride-booking-screen')),
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

Future<void> _scrollBackTo(WidgetTester tester, Finder target) async {
  final list = find.byKey(const Key('ride-booking-screen'));
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    expect(list, findsOneWidget);
    await tester.drag(list, const Offset(0, 260));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

class _Sessions {
  const _Sessions(this.journey, this.ride);

  final JourneySession journey;
  final RideSession ride;

  void dispose() {
    journey.dispose();
    ride.dispose();
  }
}
